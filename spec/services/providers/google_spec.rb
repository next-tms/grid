require 'rails_helper'

RSpec.describe(Providers::Google) do
  subject(:provider) { described_class.new(query) }

  let(:query) do
    AddressQuery.new(
      address_lines: ['1600 Amphitheatre Pkwy'],
      administrative_area: 'CA',
      locality: 'Mountain View',
      postal_code: '94043',
      region_code: 'US'
    )
  end
  let(:request) do
    stub_request(:post, described_class::SEARCH_ENDPOINT.to_s).with(
      body: { pageSize: 5, regionCode: 'US', textQuery: query.key }.to_json,
      headers: { 'X-Goog-Api-Key' => 'key', 'X-Goog-FieldMask' => described_class::FIELD_MASK }
    )
  end

  before do
    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('GOOGLE_API_KEY').and_return('key'))
  end

  describe '.authority' do
    it { expect(described_class.authority).to(eq(:commercial)) }
  end

  describe '.cache_duration' do
    it { expect(described_class.cache_duration).to(eq(0.seconds)) }
  end

  describe '.cost' do
    it { expect(described_class.cost).to(eq(:high)) }
  end

  describe '.credential_keys' do
    it { expect(described_class.credential_keys).to(eq(['GOOGLE_API_KEY'])) }
  end

  describe '.key' do
    it { expect(described_class.key).to(eq('google')) }
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[business_details geocode])) }
  end

  describe '.stores_content?' do
    it { expect(described_class.stores_content?).to(be(false)) }
  end

  describe '#call' do
    let(:validation) { provider.call }

    context 'when Google finds places' do
      before { request.to_return(body: Rails.root.join('spec/fixtures/google/text_search.json').read) }

      it do
        expect(validation).to(
          have_attributes(
            geocode_granularity: 'PREMISE',
            latitude: BigDecimal('37.4220094'),
            longitude: BigDecimal('-122.0847516'),
            permanently_closed: nil,
            provider: 'google',
            provider_identifier: 'ChIJtest-address-1600',
            region_code: 'US',
            types: ['premise', 'street_address']
          )
        )
      end

      it do
        expect(validation.place_details).to(
          eq(
            [
              {
                name: 'Googleplex',
                permanently_closed: false,
                provider_identifier: 'ChIJtest-googleplex',
                types: ['corporate_office', 'establishment', 'point_of_interest']
              },
              {
                name: 'Closed Cafe',
                permanently_closed: true,
                provider_identifier: 'ChIJtest-closed-cafe',
                types: ['cafe', 'establishment', 'food', 'point_of_interest']
              }
            ]
          )
        )
      end
    end

    context 'when Google finds only places' do
      let(:body) { JSON.parse(Rails.root.join('spec/fixtures/google/text_search.json').read) }

      before { request.to_return(body: { places: body['places'].drop(1) }.to_json) }

      it { expect(validation).to(have_attributes(geocode_granularity: 'PREMISE_PROXIMITY', latitude: BigDecimal('37.4219999'))) }
    end

    context 'when Google finds nothing' do
      before { request.to_return(body: '{}') }

      it { expect(validation).to(be_nil) }
    end

    context 'when Google finds only other addresses' do
      before { request.to_return(body: { places: [{ formattedAddress: '1 Main St, Mountain View, CA', id: 'other' }] }.to_json) }

      it { expect(validation).to(be_nil) }
    end
  end

  describe '#supports?' do
    it { is_expected.to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(postal_code: '94043', region_code: 'US'))).not_to(be_supports) }
    it { expect(described_class.new(Location.new(latitude: 0, longitude: 0))).not_to(be_supports) }
  end
end
