require 'rails_helper'

RSpec.describe(GeoNames::City) do
  describe '.nearest' do
    let!(:bend) { create(:geo_names_city) }
    let!(:vale) do
      create(:geo_names_city, latitude: 43.98211, longitude: -117.23823, name: 'Vale', population: 1_874, time_zone: 'America/Boise')
    end

    it { expect(described_class.nearest(44.0582, -121.3153)).to(eq(bend)) }
    it { expect(described_class.nearest(43.9, -117.5)).to(eq(vale)) }
    it { expect(described_class.nearest(44.5, -119.5)).to(eq(bend)) }
    it { expect(described_class.nearest(0, 0)).to(be_nil) }
  end

  describe '#distance_to' do
    it { expect(build(:geo_names_city, latitude: 60, longitude: 10).distance_to(60, 12)).to(be_within(0.001).of(1)) }
  end
end
