require 'rails_helper'

RSpec.describe(Providers::GeoNames) do
  subject(:provider) { described_class.new(query) }

  let(:query) { AddressQuery.new(postal_code: '97701', region_code: 'US') }

  before do
    allow(ENV).to(receive(:[]).and_call_original)
    allow(ENV).to(receive(:[]).with('GEONAMES_USERNAME').and_return('grid'))
    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('GEONAMES_USERNAME').and_return('grid'))
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

  describe '.configured?' do
    it { expect(described_class).to(be_configured) }

    context 'without a username' do
      before { allow(ENV).to(receive(:[]).with('GEONAMES_USERNAME').and_return(nil)) }

      it { expect(described_class).to(be_configured) }

      context 'without the file' do
        before { allow(GeoNames::PostalCode).to(receive(:available?).and_return(false)) }

        it { expect(described_class).not_to(be_configured) }
      end
    end
  end

  describe '.credential_keys' do
    it { expect(described_class.credential_keys).to(eq(['GEONAMES_USERNAME'])) }
  end

  describe '.key' do
    it { expect(described_class.key).to(eq('geo_names')) }
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[geocode time_zone verification])) }
  end

  describe '#call' do
    context 'with the GeoNames file' do
      before { create(:geo_names_postal_code) }

      it do
        expect(provider.call).to(
          have_attributes(administrative_area: 'OR', latitude: 44.0848, locality: 'Bend', postal_code: '97701', region_code: 'US')
        )
      end

      it do
        provider.call

        expect(a_request(:any, /geonames/)).not_to(have_been_made)
      end

      context 'with an unknown postal code' do
        let(:query) { AddressQuery.new(postal_code: '00000', region_code: 'US') }

        it { expect(provider.call).to(be_nil) }
      end
    end

    context 'without the GeoNames file' do
      let(:request) do
        stub_request(:get, described_class::POSTAL_CODE_ENDPOINT.to_s).with(query: { country: 'US', postalcode: '97701', username: 'grid' })
      end
      let(:validation) { provider.call }

      before { allow(GeoNames::PostalCode).to(receive(:available?).and_return(false)) }

      context 'when GeoNames knows the postal code' do
        before { request.to_return(body: Rails.root.join('spec/fixtures/geo_names/postal_code.json').read) }

        it do
          expect(validation).to(
            have_attributes(
              administrative_area: 'OR',
              geocode_granularity: 'OTHER',
              latitude: BigDecimal('44.0848'),
              locality: 'Bend',
              longitude: BigDecimal('-121.2969'),
              postal_code: '97701',
              provider: 'geo_names',
              region_code: 'US',
              validation_granularity: 'OTHER'
            )
          )
        end
      end

      context 'when GeoNames does not know the postal code' do
        before { request.to_return(body: '{"postalcodes":[]}') }

        it { expect(validation).to(be_nil) }
      end

      context 'when GeoNames reports an error' do
        before { request.to_return(body: '{"status":{"message":"user does not exist.","value":10}}') }

        it { expect { validation }.to(raise_error(Providers::Error, 'geo_names failed: user does not exist.')) }
      end
    end
  end

  describe '#supports?' do
    it { is_expected.to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(postal_code: 'SW1A 2AA', region_code: 'GB'))).to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(address_lines: ['1 Main St'], postal_code: '97701'))).not_to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(postal_code: '97701'))).not_to(be_supports) }
    it { expect(described_class.new(Location.new(latitude: 1, longitude: 2))).to(be_supports) }

    context 'without a username' do
      before { allow(ENV).to(receive(:[]).with('GEONAMES_USERNAME').and_return(nil)) }

      it { is_expected.to(be_supports) }
      it { expect(described_class.new(Location.new(latitude: 1, longitude: 2))).to(be_supports) }

      context 'without the file' do
        before { allow(GeoNames::PostalCode).to(receive(:available?).and_return(false)) }

        it { is_expected.not_to(be_supports) }
        it { expect(described_class.new(Location.new(latitude: 1, longitude: 2))).not_to(be_supports) }
      end
    end
  end

  describe '#time_zone_name' do
    let(:query) { Location.new(latitude: 44.0848, longitude: -121.2969) }
    let(:request) do
      stub_request(:get, described_class::TIME_ZONE_ENDPOINT.to_s).with(query: { lat: '44.0848', lng: '-121.2969', username: 'grid' })
    end

    context 'with a time zone' do
      before { request.to_return(body: '{"timezoneId":"America/Los_Angeles","countryCode":"US"}') }

      it { expect(provider.time_zone_name).to(eq('America/Los_Angeles')) }
    end

    context 'without a time zone' do
      before { request.to_return(body: '{"countryCode":""}') }

      it { expect(provider.time_zone_name).to(be_nil) }
    end

    context 'without a username' do
      before do
        allow(ENV).to(receive(:[]).with('GEONAMES_USERNAME').and_return(nil))
        create(:geo_names_city)
      end

      it { expect(provider.time_zone_name).to(eq('America/Los_Angeles')) }

      it do
        provider.time_zone_name

        expect(a_request(:any, /geonames/)).not_to(have_been_made)
      end
    end
  end
end
