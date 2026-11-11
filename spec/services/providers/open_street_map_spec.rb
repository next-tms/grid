require 'rails_helper'

RSpec.describe(Providers::OpenStreetMap) do
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
    stub_request(:get, 'https://nominatim.openstreetmap.org/search').with(
      headers: { 'User-Agent' => described_class::USER_AGENT },
      query: {
        city: 'Mountain View',
        countrycodes: 'us',
        extratags: '1',
        format: 'jsonv2',
        limit: '10',
        postalcode: '94043',
        state: 'CA',
        street: '1600 Amphitheatre Pkwy'
      }
    )
  end
  let(:cafe) do
    {
      category: 'amenity',
      display_name: 'Open Cafe, 1600, Amphitheatre Parkway, Mountain View, California, 94043, United States',
      lat: '37.4221',
      lon: '-122.0841',
      name: 'Open Cafe',
      osm_id: 42,
      osm_type: 'node',
      place_rank: 30,
      type: 'cafe'
    }
  end
  let(:result) do
    {
      category: 'building',
      display_name: '1600, Amphitheatre Parkway, Mountain View, California, 94043, United States',
      lat: '37.4224',
      lon: '-122.0842',
      name: '',
      osm_id: 23_733_659,
      osm_type: 'way',
      place_rank: 30,
      type: 'yes'
    }
  end

  describe '.authority' do
    it { expect(described_class.authority).to(eq(:open_data)) }
  end

  describe '.cache_duration' do
    it { expect(described_class.cache_duration).to(eq(90.days)) }
  end

  describe '.cost' do
    it { expect(described_class.cost).to(eq(:free)) }
  end

  describe '.key' do
    it { expect(described_class.key).to(eq('open_street_map')) }
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[business_details dock geocode])) }
  end

  describe '#call' do
    let(:validation) { provider.call }

    context 'when Nominatim finds a building' do
      before { request.to_return(body: [result].to_json) }

      it do
        expect(validation).to(
          have_attributes(
            geocode_granularity: 'PREMISE',
            latitude: 37.4224,
            longitude: -122.0842,
            provider: 'open_street_map',
            place_details: [],
            provider_identifier: 'way/23733659',
            region_code: 'US',
            validation_granularity: nil
          )
        )
      end

      it { expect(validation.dock).to(be_nil) }
    end

    context 'when Nominatim finds a loading dock at the building' do
      let(:dock) { result.merge(category: 'amenity', osm_id: 9, osm_type: 'node', type: 'loading_dock') }

      before { request.to_return(body: [result, dock].to_json) }

      it { expect(validation).to(have_attributes(dock: true, place_details: [], provider_identifier: 'way/23733659')) }
    end

    context 'when Nominatim finds a loading dock at another number' do
      let(:dock) { result.merge(category: 'amenity', display_name: '1, Main Street', osm_type: 'node', type: 'loading_dock') }

      before { request.to_return(body: [result, dock].to_json) }

      it { expect(validation.dock).to(be_nil) }
    end

    context 'when the building is tagged without a loading dock' do
      before { request.to_return(body: [result.merge(extratags: { building: 'warehouse', loading_dock: 'no' })].to_json) }

      it { expect(validation.dock).to(be(false)) }
    end

    context 'when Nominatim finds a building and a business' do
      before { request.to_return(body: [result, cafe].to_json) }

      it { expect(validation.provider_identifier).to(eq('way/23733659')) }

      it do
        expect(validation.place_details).to(
          eq([{ name: 'Open Cafe', permanently_closed: nil, provider_identifier: 'node/42', types: ['amenity=cafe'] }])
        )
      end
    end

    context 'when Nominatim finds a business first' do
      before { request.to_return(body: [cafe, result].to_json) }

      it { expect(validation).to(have_attributes(latitude: 37.4221, provider_identifier: 'way/23733659')) }
    end

    context 'when Nominatim finds a military base' do
      let(:base) { result.merge(category: 'military', name: 'Fort Example', osm_id: 7, type: 'base') }

      before { request.to_return(body: [result, base].to_json) }

      it { expect(validation.place_details).to(contain_exactly(include(name: 'Fort Example', types: ['military=base']))) }
    end

    context 'when Nominatim finds a named building' do
      before { request.to_return(body: [result.merge(name: 'Tower')].to_json) }

      it { expect(validation.place_details).to(be_empty) }
    end

    context 'when Nominatim finds a business at another number' do
      before { request.to_return(body: [result, cafe.merge(display_name: 'Open Cafe, 1, Main Street, Mountain View')].to_json) }

      it { expect(validation.place_details).to(be_empty) }
    end

    context 'when Nominatim finds a street' do
      before { request.to_return(body: [result.merge(place_rank: 26)].to_json) }

      it { expect(validation).to(have_attributes(dock: nil, geocode_granularity: 'ROUTE')) }
    end

    context 'when Nominatim finds a city' do
      before { request.to_return(body: [result.merge(place_rank: 16)].to_json) }

      it { expect(validation.geocode_granularity).to(eq('OTHER')) }
    end

    context 'when Nominatim finds nothing' do
      before { request.to_return(body: '[]') }

      it { expect(validation).to(be_nil) }
    end

    context 'with NOMINATIM_URL' do
      before do
        allow(ENV).to(receive(:fetch).and_call_original)
        allow(ENV).to(receive(:fetch).with('NOMINATIM_URL', described_class::DEFAULT_URL).and_return('http://nominatim.internal:8080'))
        stub_request(:get, %r{\Ahttp://nominatim.internal:8080/search}).to_return(body: [result].to_json)
      end

      it { expect(validation.provider_identifier).to(eq('way/23733659')) }
    end
  end

  describe '#supports?' do
    it { is_expected.to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(postal_code: '94043', region_code: 'US'))).to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(address_lines: ['1 Main St']))).not_to(be_supports) }
    it { expect(described_class.new(Location.new(latitude: 0, longitude: 0))).not_to(be_supports) }
  end
end
