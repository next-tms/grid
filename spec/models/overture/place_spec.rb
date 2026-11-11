require 'rails_helper'

RSpec.describe(Overture::Place) do
  subject(:overture_place) { build(:overture_place, id: 'overture-1') }

  describe '.available?' do
    it { expect(described_class).to(be_available) }

    context 'with a file for another schema version' do
      before do
        allow(Overture::Schema).to(receive(:version).and_return('000000000000'))
        allow(Rails.logger).to(receive(:warn))
      end

      it { expect(described_class).not_to(be_available) }
    end

    context 'with an empty file' do
      before do
        allow(File).to(receive(:size?).and_call_original)
        allow(File).to(receive(:size?).with(described_class.connection_db_config.database).and_return(nil))
      end

      it { expect(described_class).not_to(be_available) }
    end
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(include('administrative_area', 'postal_code', 'region_code')) }
    it { expect(described_class.ransackable_attributes).not_to(include('address_key')) }
  end

  describe '#address_lines' do
    it { expect(overture_place.address_lines).to(eq([])) }
    it { expect(build(:overture_place, freeform: '1600 Amphitheatre Pkwy').address_lines).to(eq(['1600 Amphitheatre Pkwy'])) }
  end

  describe '#freight_kit_location_types' do
    it { expect(overture_place.freight_kit_location_types).to(eq(['restaurant'])) }
  end

  describe '#location' do
    it { expect(overture_place.location).to(be_nil) }

    context 'with a point' do
      subject(:overture_place) { build(:overture_place, latitude: 37.42, longitude: -122.08) }

      it do
        expect(overture_place.location).to(
          eq(Location.new(authority: :open_data, granularity: 'PREMISE_PROXIMITY', latitude: 37.42, longitude: -122.08))
        )
      end
    end
  end

  describe '#permanently_closed' do
    it { expect(overture_place.permanently_closed).to(be_nil) }
    it { expect(build(:overture_place, operating_status: 'open').permanently_closed).to(be(false)) }
    it { expect(build(:overture_place, operating_status: 'permanently_closed').permanently_closed).to(be(true)) }
  end

  describe '#place_details' do
    it do
      expect(overture_place.place_details).to(
        eq(name: 'Open Cafe', permanently_closed: nil, provider_identifier: 'overture-1', types: ['coffee_shop'])
      )
    end
  end

  describe '#types' do
    it { expect(build(:overture_place, primary_category: 'coffee_shop').types).to(eq(['coffee_shop'])) }
    it { expect(build(:overture_place, primary_category: 'cafe').types).to(eq(['coffee_shop', 'cafe'])) }
  end
end
