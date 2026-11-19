require 'rails_helper'

RSpec.describe(Types::QueryType) do
  subject(:result) { execute(query, variables) }

  let(:address) do
    { addressLines: ['1600 Amphitheatre Pkwy'], administrativeArea: 'CA', locality: 'Mountain View', postalCode: '94043', regionCode: 'US' }
  end
  let(:cafe) do
    {
      authority: 'COMMERCIAL',
      expires_at: 1.minute.from_now.iso8601,
      id: Place.find_by!(name: 'Fake Cafe').id,
      name: 'Fake Cafe',
      permanently_closed: false,
      types: ['cafe', 'establishment', 'food', 'point_of_interest']
    }
  end
  let(:place_fields) { 'authority expiresAt id name permanentlyClosed types' }
  let(:providers) { [Providers::Fake] }
  let(:variables) { {} }

  before do
    freeze_time
    create(:country, iso3166_1_alpha2: 'US')
    allow(Providers).to(receive(:enabled).and_return(providers))
  end

  describe 'fetchCountries' do
    let(:countries) { result.dig(:data, :fetch_countries) }
    let(:query) do
      <<~GRAPHQL
        query($name: String) {
          fetchCountries(name: $name) {
            alpha2 alpha3 name numeric postalCode postalCodeFormat postalCodeLabel
            regions { abbreviation iso31662 name }
          }
        }
      GRAPHQL
    end

    it { expect(countries.size).to(eq(ISO3166::Country.all.size)) }
    it { expect(countries.filter_map { it[:postal_code_format] }).to(all(satisfy { Regexp.new("\\A(?:#{it})\\z") })) }

    context 'with a name' do
      let(:country) do
        {
          alpha2: 'US',
          alpha3: 'USA',
          name: 'United States of America',
          numeric: 840,
          postal_code: true,
          postal_code_format: '(\\d{5})(?:[ \\-](\\d{4}))?',
          postal_code_label: 'ZIP'
        }
      end
      let(:variables) { { name: ' United States of America ' } }

      it { expect(countries).to(contain_exactly(include(country))) }
      it { expect(countries.first[:regions]).to(include({ abbreviation: 'TX', iso31662: 'US-TX', name: 'Texas' })) }
    end

    context 'with a country without a local postal code label' do
      let(:format) { '[ABCEGHJKLMNPRSTVXY]\\d[ABCEGHJ-NPRSTV-Z] ?\\d[ABCEGHJ-NPRSTV-Z]\\d' }
      let(:variables) { { name: 'CA' } }

      it { expect(countries.first).to(include(postal_code_format: format, postal_code_label: 'Postal code')) }
    end

    context 'with a country without postal codes' do
      let(:variables) { { name: 'AE' } }

      it { expect(countries.first).to(include(postal_code: false, postal_code_format: nil)) }
    end

    context 'with an unknown name' do
      let(:variables) { { name: 'Atlantis' } }

      it { expect(countries).to(eq([])) }
    end
  end

  describe 'fetchPlace' do
    let(:query) { "query($id: IdentifierInput!) { fetchPlace(id: $id) { #{place_fields} } }" }
    let(:variables) { { id: { provider:, value: id }.compact } }
    let(:provider) { nil }

    before { PlaceSearch.new(create(:address)).call }

    context 'with a known place' do
      let(:id) { Place.find_by!(name: 'Fake Cafe').id }

      it { expect(result).to(eq(data: { fetch_place: cafe })) }
    end

    context 'with the fingerprint field' do
      let(:id) { Place.find_by!(name: 'Fake Cafe').id }
      let(:place_fields) { 'fingerprint' }

      it { expect(result).to(eq(data: { fetch_place: { fingerprint: Fingerprint.of([Place.find(id).validation]) } })) }
    end

    context 'with the provider field' do
      let(:id) { Place.find_by!(name: 'Fake Cafe').id }
      let(:place_fields) { 'provider' }

      it { expect(result).to(eq(data: { fetch_place: { provider: 'FAKE' } })) }
    end

    context 'with an Overture place' do
      let(:id) { Place.find_by!(name: 'Open Cafe').id }
      let(:place) { { freight_kit_location_types: ['RESTAURANT'], provider: 'OVERTURE', types: ['coffee_shop'] } }
      let(:place_fields) { 'freightKitLocationTypes provider types' }
      let(:providers) { [Providers::Overture] }

      before do
        create(:overture_place, address_key: AddressKey.for(Address.last.query), basic_category: 'coffee_shop')
        PlaceSearch.new(Address.last).call
      end

      it { expect(result).to(eq(data: { fetch_place: place })) }
    end

    context 'with the Grid ID of a place that Grid did not store' do
      let(:id) { PlaceId.for('overture', 'overture-1') }
      let(:place_fields) { 'id name provider' }
      let(:providers) { [Providers::Overture] }

      before { create(:overture_place, address_key: '1 MAIN ST, 94043, US', freeform: '1 Main St', id: 'overture-1') }

      it { expect(result).to(eq(data: { fetch_place: { id:, name: 'Open Cafe', provider: 'OVERTURE' } })) }
      it { expect { result }.to(change(Place, :count).by(1)) }

      it do
        result

        expect { execute(query, variables) }.not_to(change { [Address.count, Place.count, Validation.count] })
      end
    end

    context 'with the provider ID of a place that Grid did not store' do
      let(:id) { 'overture-1' }
      let(:place_fields) { 'id' }
      let(:provider) { 'OVERTURE' }
      let(:providers) { [Providers::Overture] }

      before { create(:overture_place, address_key: '1 MAIN ST, 94043, US', freeform: '1 Main St', id: 'overture-1') }

      it { expect(result).to(eq(data: { fetch_place: { id: PlaceId.for('overture', 'overture-1') } })) }
    end

    context 'with a provider ID' do
      let(:id) { 'fake-cafe' }
      let(:provider) { 'FAKE' }

      it { expect(result).to(eq(data: { fetch_place: cafe })) }
    end

    context 'with an unknown provider ID' do
      let(:id) { 'unknown' }
      let(:provider) { 'FAKE' }

      it { expect(result).to(eq(data: { fetch_place: nil })) }
    end

    context 'with an unknown place' do
      let(:id) { 'unknown' }

      it { expect(result).to(eq(data: { fetch_place: nil })) }
    end
  end

  describe 'fetchPlaces' do
    let(:query) { "query($address: AddressInput) { fetchPlaces(address: $address) { nodes { #{place_fields} } } }" }
    let(:variables) { { address: } }

    it { expect(result.dig(:data, :fetch_places, :nodes)).to(contain_exactly(cafe, include(name: 'Fake Office'))) }

    context 'with address fields' do
      let(:place_fields) do
        'addressId addressLines administrativeArea locality location { granularity latitude longitude } postalCode regionCode'
      end

      it do
        expect(result.dig(:data, :fetch_places, :nodes, 0)).to(
          eq(
            address_id: Address.last.id,
            address_lines: ['1600 AMPHITHEATRE PKWY'],
            administrative_area: nil,
            locality: nil,
            location: { granularity: 'PREMISE', latitude: 37.42241, longitude: -122.08561 },
            postal_code: '94043',
            region_code: 'US'
          )
        )
      end
    end

    context 'with a ZIP code only' do
      let(:variables) { { address: { postalCode: '90012', regionCode: 'US' } } }

      it { expect(result).to(eq(data: { fetch_places: { nodes: [] } })) }
    end

    context 'with an unknown country' do
      let(:variables) { { address: { addressLines: ['1 Main St'], regionCode: 'ZZ' } } }

      it { expect(result).to(eq(data: { fetch_places: nil })) }
    end

    context 'with an address and a filter' do
      let(:message) { 'fetchPlaces must include exactly one of the following arguments: address, filter.' }
      let(:query) { 'query($address: AddressInput) { fetchPlaces(address: $address, filter: {}) { nodes { id } } }' }

      it { expect(result.dig(:errors, 0, :message)).to(eq(message)) }
    end

    context 'with a filter' do
      let(:names) { places.map { it[:name] } }
      let(:place_fields) { 'name' }
      let(:places) { result.dig(:data, :fetch_places, :nodes) }
      let(:providers) { [Providers::Overture] }
      let(:query) do
        <<~GRAPHQL
          query($after: String, $filter: PlaceFilterInput, $first: Int, $sort: [PlaceSort!]) {
            fetchPlaces(after: $after, filter: $filter, first: $first, sort: $sort) {
              totalCount
              pageInfo { endCursor hasNextPage }
              nodes { #{place_fields} }
            }
          }
        GRAPHQL
      end
      let(:variables) { { filter: {} } }

      before do
        create(:overture_place, address_key: '1 MAIN ST, 94043, US', basic_category: 'coffee_shop', freeform: '1 Main St',
                                id: 'overture-cafe', latitude: 37.42, longitude: -122.08, name: 'Open Cafe')
        create(:overture_place, address_key: '1701 AIRPORT BLVD, 95110, US', basic_category: 'airport', freeform: '1701 Airport Blvd',
                                id: 'overture-airport', locality: 'San Jose', name: 'San Jose Airport', postcode: '95110')
        create(:overture_place, address_key: '2 CONGRESS AVE, 78701, US', basic_category: 'restaurant', freeform: '2 Congress Ave',
                                id: 'overture-diner', name: 'Austin Diner', operating_status: 'permanently_closed', postcode: '78701',
                                primary_category: 'diner', region: 'TX')
      end

      it { expect(names).to(eq(['San Jose Airport', 'Open Cafe', 'Austin Diner'])) }
      it { expect(result.dig(:data, :fetch_places, :total_count)).to(eq(3)) }
      it { expect { result }.not_to(change { [Address.count, Place.count, Validation.count] }) }

      context 'with a stored place' do
        let(:place_fields) { 'addressId id' }
        let(:variables) { { filter: { nameEq: 'Open Cafe' } } }

        before do
          execute('query($id: IdentifierInput!) { fetchPlace(id: $id) { id } }', id: { value: PlaceId.for('overture', 'overture-cafe') })
        end

        it { expect(places).to(eq([{ address_id: Address.sole.id, id: PlaceId.for('overture', 'overture-cafe') }])) }
      end

      context 'with all place fields' do
        let(:place) do
          {
            address_id: nil,
            address_lines: ['1 MAIN ST'],
            administrative_area: 'CA',
            authority: 'OPEN_DATA',
            freight_kit_location_types: ['RESTAURANT'],
            id: PlaceId.for('overture', 'overture-cafe'),
            locality: 'Mountain View',
            location: { granularity: 'PREMISE_PROXIMITY', latitude: 37.42, longitude: -122.08 },
            name: 'Open Cafe',
            permanently_closed: nil,
            postal_code: '94043',
            provider: 'OVERTURE',
            region_code: 'US',
            types: ['coffee_shop']
          }
        end
        let(:place_fields) do
          'addressId addressLines administrativeArea authority freightKitLocationTypes id locality ' \
            'location { granularity latitude longitude } name permanentlyClosed postalCode provider regionCode types'
        end
        let(:variables) { { filter: { nameEq: 'Open Cafe' } } }

        it { expect(places).to(eq([place])) }
      end

      context 'with FreightKit location types and a state' do
        let(:variables) { { filter: { administrativeAreaEq: 'CA', freightKitLocationTypesIn: ['RESTAURANT'] } } }

        it { expect(names).to(eq(['Open Cafe'])) }
      end

      context 'with a FreightKit location type that no place has' do
        let(:variables) { { filter: { freightKitLocationTypesIn: ['MOTEL'] } } }

        it { expect(places).to(eq([])) }
      end

      context 'with a place type' do
        let(:variables) { { filter: { typeIn: ['airport', 'diner'] } } }

        it { expect(names).to(eq(['San Jose Airport', 'Austin Diner'])) }
      end

      context 'with permanently closed places' do
        let(:variables) { { filter: { permanentlyClosed: true } } }

        it { expect(names).to(eq(['Austin Diner'])) }
      end

      context 'without permanently closed places' do
        let(:variables) { { filter: { permanentlyClosed: false } } }

        it { expect(names).to(eq(['San Jose Airport', 'Open Cafe'])) }
      end

      context 'with OR filters' do
        let(:variables) { { filter: { or: [{ localityEq: 'San Jose' }, { postalCodeStart: '787' }] } } }

        it { expect(names).to(eq(['San Jose Airport', 'Austin Diner'])) }
      end

      context 'with a box around a location' do
        let(:variables) { { filter: { latitudeGteq: 37, latitudeLteq: 38, longitudeGteq: -123, longitudeLteq: -122 } } }

        it { expect(names).to(eq(['Open Cafe'])) }
      end

      context 'with a sort' do
        let(:variables) { { filter: {}, sort: ['NAME_ASC'] } }

        it { expect(names).to(eq(['Austin Diner', 'Open Cafe', 'San Jose Airport'])) }
      end

      context 'with pages' do
        let(:page) { execute(query, filter: {}, first: 2) }
        let(:variables) { { after: page.dig(:data, :fetch_places, :page_info, :end_cursor), filter: {}, first: 2 } }

        it { expect(page.dig(:data, :fetch_places, :page_info, :has_next_page)).to(be(true)) }
        it { expect(names).to(eq(['Austin Diner'])) }
      end

      context 'with a page that is too large' do
        let(:variables) { { filter: {}, first: 1000 } }

        it { expect(places.size).to(eq(3)) }
        it { expect(GridSchema.default_max_page_size).to(eq(100)) }
      end

      context 'without a provider that searches places' do
        before { allow(Overture::Place).to(receive(:available?).and_return(false)) }

        it { expect(result[:errors]).to(contain_exactly(include(message: 'No provider can search places by filter.'))) }
      end
    end
  end

  describe 'fetchTimeZone' do
    let(:query) do
      <<~GRAPHQL
        query($address: AddressInput, $id: String, $location: LocationInput) {
          fetchTimeZone(address: $address, id: $id, location: $location) { authority expiresAt id }
        }
      GRAPHQL
    end
    let(:time_zone) { { authority: 'COMMERCIAL', expires_at: 1.minute.from_now.iso8601, id: 'America/Los_Angeles' } }
    let(:variables) { { location: { latitude: 37.42241, longitude: -122.08561 } } }

    it { expect(result).to(eq(data: { fetch_time_zone: time_zone })) }

    context 'with the fingerprint field' do
      let(:query) { '{ fetchTimeZone(id: "America/Chicago") { fingerprint } }' }

      it { expect(result).to(eq(data: { fetch_time_zone: { fingerprint: Fingerprint.of([TimeZone.find('America/Chicago')]) } })) }
    end

    context 'with an address' do
      let(:variables) { { address: } }

      before { allow(TimeZoneLookup).to(receive(:new).and_call_original) }

      it { expect(result).to(eq(data: { fetch_time_zone: time_zone })) }

      it do
        result

        expect(TimeZoneLookup).not_to(have_received(:new))
      end
    end

    context 'with an IANA name' do
      let(:variables) { { id: 'America/Chicago' } }

      it { expect(result).to(eq(data: { fetch_time_zone: { authority: nil, expires_at: nil, id: 'America/Chicago' } })) }
    end

    context 'with an unknown IANA name' do
      let(:variables) { { id: 'Mars/Olympus_Mons' } }

      it { expect(result).to(eq(data: { fetch_time_zone: nil })) }
    end

    context 'with two arguments' do
      let(:message) { 'fetchTimeZone must include exactly one of the following arguments: address, id, location.' }
      let(:variables) { { id: 'America/Chicago', location: { latitude: 0, longitude: 0 } } }

      it { expect(result.dig(:errors, 0, :message)).to(eq(message)) }
    end

    context 'with a Plus Code' do
      let(:variables) { { location: { plusCode: '849VCWC7+XQ' } } }

      it { expect(result).to(eq(data: { fetch_time_zone: time_zone })) }
    end

    context 'with a short Plus Code' do
      let(:variables) { { location: { plusCode: 'CWC7+XQ' } } }

      it { expect(result.dig(:errors, 0, :message)).to(eq('plusCode must be a full Plus Code')) }
    end

    context 'with a latitude only' do
      let(:message) { 'LocationInput must include exactly one of the following arguments: plusCode, (latitude and longitude).' }
      let(:variables) { { location: { latitude: 37.42241 } } }

      it { expect(result.dig(:errors, 0, :message)).to(eq(message)) }
    end

    context 'with an invalid latitude' do
      let(:variables) { { location: { latitude: 91, longitude: 0 } } }

      it { expect(result.dig(:errors, 0, :message)).to(eq('latitude must be less than or equal to 90')) }
    end

    context 'when the provider fails' do
      let(:adapter) { instance_double(Providers::Fake, supports?: true) }

      before do
        allow(adapter).to(receive(:time_zone_name).and_raise(Providers::Error, 'down'))
        allow(Providers::Fake).to(receive(:new).and_return(adapter))
        allow(Sentry).to(receive(:capture_exception))
      end

      it { expect(result[:data]).to(eq(fetch_time_zone: nil)) }
      it { expect(result[:errors]).to(contain_exactly(include(message: 'down', path: ['fetchTimeZone']))) }

      it do
        result

        expect(Sentry).to(have_received(:capture_exception).with(instance_of(Providers::Error)))
      end
    end
  end

  describe 'fetchTimeZones' do
    let(:query) { 'query($name: String, $regionCode: String) { fetchTimeZones(name: $name, regionCode: $regionCode) { id } }' }
    let(:variables) { { name: 'new york', regionCode: 'US' } }

    it { expect(result).to(eq(data: { fetch_time_zones: [{ id: 'America/New_York' }] })) }
  end

  describe 'verifyAddress' do
    let(:query) do
      <<~GRAPHQL
        query($address: AddressInput!) {
          verifyAddress(address: $address) {
            addressId addressLines administrativeArea authority { highest lowest quality } business expiresAt locality poBox postalCode
            residential verified
          }
        }
      GRAPHQL
    end
    let(:variables) { { address: } }

    it do
      expect(result.dig(:data, :verify_address)).to(
        eq(
          address_id: Address.last.id,
          address_lines: ['1600 Amphitheatre Pkwy'],
          administrative_area: 'CA',
          authority: { highest: 'COMMERCIAL', lowest: 'COMMERCIAL', quality: 0.2 },
          business: true,
          expires_at: 1.minute.from_now.iso8601,
          locality: 'Mountain View',
          po_box: false,
          postal_code: '94043',
          residential: false,
          verified: true
        )
      )
    end

    context 'with a ZIP code only' do
      let(:variables) { { address: { postalCode: '90012', regionCode: 'US' } } }

      it { expect(result.dig(:data, :verify_address)).to(include(locality: 'Los Angeles', verified: false)) }
    end

    context 'without providers' do
      let(:providers) { [] }

      let(:normalized) do
        {
          address_lines: ['1600 AMPHITHEATRE PKWY'],
          authority: { highest: 'LOCAL', lowest: 'LOCAL', quality: 0.0 },
          expires_at: nil,
          locality: 'MOUNTAIN VIEW'
        }
      end

      it { expect(result.dig(:data, :verify_address)).to(include(**normalized, verified: false)) }
    end

    context 'with an unknown country' do
      let(:variables) { { address: { addressLines: ['1 Main St'], regionCode: 'ZZ' } } }

      it { expect(result).to(eq(data: { verify_address: nil })) }
    end
  end
end
