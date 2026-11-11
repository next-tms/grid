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
