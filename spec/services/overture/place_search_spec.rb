require 'rails_helper'

RSpec.describe(Overture::PlaceSearch) do
  subject(:search) { described_class.new(filter:, sort:) }

  let(:filter) { {} }
  let(:sort) { [] }

  before do
    create(:overture_place, basic_category: 'coffee_shop', id: 'overture-b', name: 'B Cafe')
    create(:overture_place, basic_category: 'airport', id: 'overture-a', name: 'A Airport', region: 'TX')
  end

  describe '#call' do
    it { expect(search.call.map(&:id)).to(eq(['overture-a', 'overture-b'])) }

    context 'with a FreightKit location type' do
      let(:filter) { { freight_kit_location_types_in: ['airport'] } }

      it { expect(search.call.map(&:id)).to(eq(['overture-a'])) }
    end

    context 'with a FreightKit location type inside OR filters' do
      let(:filter) { { or: [{ freight_kit_location_types_in: ['restaurant'] }, { administrative_area_eq: 'TX' }] } }

      it { expect(search.call.map(&:id)).to(eq(['overture-a', 'overture-b'])) }
    end

    context 'with a FreightKit location type and another condition' do
      let(:filter) { { administrative_area_eq: 'TX', freight_kit_location_types_in: ['restaurant'] } }

      it { expect(search.call).to(be_empty) }
    end

    context 'with a box around a location' do
      let(:filter) { { latitude_gteq: 37, latitude_lteq: 38, longitude_gteq: -123, longitude_lteq: -122 } }

      before { create(:overture_place, id: 'overture-c', latitude: 37.42, longitude: -122.08) }

      it { expect(search.call.map(&:id)).to(eq(['overture-c'])) }
      it { expect(search.call.to_sql).to(include('INDEXED BY index_places_on_latitude_and_longitude')) }
    end

    context 'with a sort' do
      let(:sort) { ['name desc'] }

      it { expect(search.call.map(&:id)).to(eq(['overture-b', 'overture-a'])) }
    end

    context 'with an unknown condition' do
      let(:filter) { { address_key_eq: 'x' } }

      it { expect { search.call }.to(raise_error(ArgumentError)) }
    end
  end
end
