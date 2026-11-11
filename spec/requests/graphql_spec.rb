require 'rails_helper'

RSpec.describe('GraphQL') do
  subject { response }

  let(:providers) { [Providers::Fake] }
  let(:query) { 'query($name: String!) { __type(name: $name) { name } }' }
  let(:time_zone_query) { 'query($location: LocationInput!) { fetchTimeZone(location: $location) { id } }' }
  let(:time_zone_variables) { { location: { latitude: 37.42241, longitude: -122.08561 } }.to_json }

  before do
    freeze_time
    allow(Providers).to(receive(:enabled).and_return(providers))
  end

  describe 'GET /graphql' do
    context 'with an answer from a provider' do
      before { get('/graphql', params: { query: time_zone_query, variables: time_zone_variables }) }

      it_behaves_like('a cacheable response')
      it { expect(json).to(eq(data: { fetch_time_zone: { id: 'America/Los_Angeles' } })) }
    end

    context 'with content that Grid must not store' do
      let(:providers) { [Providers::Google] }
      let(:places_query) { 'query($address: AddressInput!) { fetchPlaces(address: $address) { name } }' }
      let(:address) { { addressLines: ['1600 Amphitheatre Pkwy'], locality: 'Mountain View', postalCode: '94043', regionCode: 'US' } }

      before do
        create(:country, iso3166_1_alpha2: 'US')
        allow(ENV).to(receive(:fetch).and_call_original)
        allow(ENV).to(receive(:fetch).with('GOOGLE_API_KEY').and_return('key'))
        stub_request(:post, Providers::Google::SEARCH_ENDPOINT.to_s)
          .to_return(body: Rails.root.join('spec/fixtures/google/text_search.json').read)
        get('/graphql', params: { query: places_query, variables: { address: }.to_json })
      end

      it { expect(json.dig(:data, :fetch_places)).to(contain_exactly({ name: 'Googleplex' }, { name: 'Closed Cafe' })) }
      it { expect(response.headers['Cache-Control']).to(eq('no-store')) }
    end

    context 'without an answer' do
      before { get('/graphql', params: { query: '{ fetchPlace(id: { value: "unknown" }) { id } }' }) }

      it { expect(json).to(eq(data: { fetch_place: nil })) }
      it { expect(response.headers['Cache-Control']).to(eq('max-age=0, private, must-revalidate')) }
    end

    context 'with an answer from tzdata' do
      before { get('/graphql', params: { query: '{ fetchTimeZone(id: "America/Chicago") { id } }' }) }

      it { expect(response.headers['Cache-Control']).to(eq('max-age=0, private, must-revalidate')) }
    end

    context 'with errors' do
      before { get('/graphql', params: { query: '{ fetchTimeZone(location: { latitude: 91, longitude: 0 }) { id } }' }) }

      it { expect(json[:errors]).to(be_present) }
      it { expect(response.headers['Cache-Control']).to(eq('max-age=0, private, must-revalidate')) }
    end

    context 'with a mutation' do
      before { get('/graphql', params: { query: 'mutation { verifyAddress }' }) }

      it { is_expected.to(have_http_status(:method_not_allowed)) }
      it { expect(response.headers['Allow']).to(eq('POST')) }
      it { expect(json).to(eq(errors: [{ message: 'Mutations require POST.' }])) }
    end
  end

  describe 'POST /graphql' do
    context 'with an answer from a provider' do
      before { post('/graphql', as: :json, params: { query: time_zone_query, variables: JSON.parse(time_zone_variables) }) }

      it { expect(json).to(eq(data: { fetch_time_zone: { id: 'America/Los_Angeles' } })) }
      it { expect(response.headers['Cache-Control']).to(eq('max-age=0, private, must-revalidate')) }
    end

    context 'with JSON variables' do
      before { post('/graphql', as: :json, params: { query:, variables: { name: 'Query' } }) }

      it { expect(json.dig(:data, :__type, :name)).to(eq('Query')) }
    end

    context 'with string variables' do
      before { post('/graphql', params: { query:, variables: { name: 'Query' }.to_json }) }

      it { expect(json.dig(:data, :__type, :name)).to(eq('Query')) }
    end

    context 'with blank variables' do
      before { post('/graphql', params: { query: '{ __typename }', variables: '' }) }

      it { expect(json.dig(:data, :__typename)).to(eq('Query')) }
    end

    context 'without variables' do
      before { post('/graphql', params: { query: '{ __typename }' }) }

      it { expect(json.dig(:data, :__typename)).to(eq('Query')) }
    end

    context 'with an error in development' do
      before do
        allow(Rails.env).to(receive(:development?).and_return(true))
        allow(GraphQL::Query).to(receive(:new).and_raise(StandardError, 'boom'))

        post('/graphql', params: { query: '{ __typename }' })
      end

      it { is_expected.to(have_http_status(:internal_server_error)) }
      it { expect(json.dig(:errors, 0, :message)).to(eq('boom')) }
    end

    context 'with an error outside development' do
      before { allow(GraphQL::Query).to(receive(:new).and_raise(StandardError, 'boom')) }

      it { expect { post('/graphql', params: { query: '{ __typename }' }) }.to(raise_error(StandardError, 'boom')) }
    end

    context 'with unexpected variables' do
      before { allow(GraphQL::Query).to(receive(:new)) }

      it { expect { post('/graphql', as: :json, params: { query:, variables: [1] }) }.to(raise_error(ArgumentError)) }
    end
  end
end
