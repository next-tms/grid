require 'rails_helper'

RSpec.describe(FreightKitLocationTypes) do
  describe '.names' do
    it { expect(described_class.names).to(include('airport', 'military_site', 'restaurant', 'school')) }
    it { expect(described_class.names).to(eq(described_class.names.sort)) }
  end

  describe '.for' do
    it { expect(described_class.for('overture', ['coffee_shop', 'coffee_shop'])).to(eq(['restaurant'])) }
    it { expect(described_class.for('google', ['cafe', 'primary_school', 'establishment'])).to(eq(['restaurant', 'school'])) }
    it { expect(described_class.for('open_street_map', ['military=base'])).to(eq(['military_site'])) }
    it { expect(described_class.for('fake', ['cafe'])).to(eq([])) }
    it { expect(described_class.for('overture', nil)).to(eq([])) }
  end

  describe '.provider_types' do
    it do
      expect(described_class.provider_types('overture', ['airport', 'brewery']))
        .to(eq(['air_transport_facility_or_service', 'airport', 'brewery']))
    end

    it { expect(described_class.provider_types('overture', ['motel', 'unknown'])).to(eq([])) }
  end

  describe '.table' do
    it { expect(described_class.table.values.map(&:keys).uniq).to(eq([['google', 'open_street_map', 'overture']])) }
  end
end
