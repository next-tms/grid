require 'rails_helper'

RSpec.describe(Providers::Fake) do
  subject(:provider) { described_class.new(query) }

  let(:query) do
    AddressQuery.new(address_lines: ['1 Main St'], administrative_area: 'CA', locality: 'Fremont', postal_code: '94536', region_code: 'US')
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[business_details geocode time_zone verification])) }
  end

  describe '#call' do
    it do
      expect(provider.call).to(
        have_attributes(
          address_lines: ['1 Main St'],
          administrative_area: 'CA',
          dpv_confirmation: 'Y',
          locality: 'Fremont',
          place_details: described_class::PLACES,
          postal_code: '94536',
          provider: 'fake',
          permanently_closed: false,
          region_code: 'US',
          types: ['establishment', 'point_of_interest'],
          validation_granularity: 'PREMISE'
        )
      )
    end

    context 'with a postal code only' do
      let(:query) { AddressQuery.new(postal_code: '94043', region_code: 'US') }

      it do
        expect(provider.call).to(
          have_attributes(
            administrative_area: 'CA',
            dpv_confirmation: nil,
            latitude: 34.05224,
            locality: 'Los Angeles',
            postal_code: '94043',
            validation_granularity: 'OTHER'
          )
        )
      end
    end
  end

  describe '#supports?' do
    it { is_expected.to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(postal_code: '94536'))).to(be_supports) }
    it { expect(described_class.new(AddressQuery.new)).not_to(be_supports) }
    it { expect(described_class.new(Location.new(latitude: 1, longitude: 2))).to(be_supports) }
  end

  describe '#time_zone_name' do
    it { expect(provider.time_zone_name).to(eq('America/Los_Angeles')) }
  end
end
