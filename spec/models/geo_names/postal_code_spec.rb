require 'rails_helper'

RSpec.describe(GeoNames::PostalCode) do
  describe '.available?' do
    it { expect(described_class).to(be_available) }
  end

  describe '.lookup' do
    let!(:full) { create(:geo_names_postal_code, country_code: 'CA', postal_code: 'T2P 1J9', place_name: 'Calgary') }
    let!(:outward) { create(:geo_names_postal_code, country_code: 'CA', postal_code: 'T3A', place_name: 'Calgary Northwest') }

    it { expect(described_class.lookup('CA', 'T2P1J9')).to(eq(full)) }
    it { expect(described_class.lookup('CA', 'T3A 0A1')).to(eq(outward)) }
    it { expect(described_class.lookup('US', 'T2P1J9')).to(be_nil) }
  end

  describe '#lookup_result' do
    it do
      expect(build(:geo_names_postal_code).lookup_result).to(
        eq(admin_code1: 'OR', country_code: 'US', lat: 44.0848, lng: -121.2969, place_name: 'Bend', postalcode: '97701')
      )
    end
  end
end
