require 'rails_helper'

RSpec.describe(Providers::Overture) do
  subject(:provider) { described_class.new(query) }

  let(:query) do
    AddressQuery.new(address_lines: ['1600 amphitheatre parkway'], locality: 'Mountain View', postal_code: '94043-1351', region_code: 'US')
  end

  describe '.authority' do
    it { expect(described_class.authority).to(eq(:open_data)) }
  end

  describe '.cache_duration' do
    it { expect(described_class.cache_duration).to(eq(1.day)) }
  end

  describe '.cost' do
    it { expect(described_class.cost).to(eq(:free)) }
  end

  describe '.key' do
    it { expect(described_class.key).to(eq('overture')) }
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[business_details geocode verification])) }
  end

  describe '#call' do
    before { create(:overture_place, id: 'overture-1') }

    it do
      expect(provider.call.place_details).to(
        eq([{ name: 'Open Cafe', permanently_closed: nil, provider_identifier: 'overture-1', types: ['coffee_shop'] }])
      )
    end

    it do
      expect(provider.call).to(
        have_attributes(administrative_area: 'CA', locality: 'Mountain View', postal_code: '94043', validation_granularity: 'PREMISE')
      )
    end

    context 'with a state name' do
      before { Overture::Place.find('overture-1').update!(region: 'California') }

      it { expect(provider.call.administrative_area).to(eq('CA')) }
    end

    context 'with coordinates' do
      before do
        Overture::Place.find('overture-1').update!(latitude: 37.42, longitude: -122.08)
        create(:overture_place, id: 'overture-north', latitude: 37.44, longitude: -122.10)
      end

      it { expect(provider.call).to(have_attributes(geocode_granularity: 'PREMISE_PROXIMITY', latitude: 37.43, longitude: -122.09)) }

      context 'with a point far away' do
        before { create(:overture_place, id: 'overture-far', latitude: 34.05, longitude: -118.24) }

        it { expect(provider.call).to(have_attributes(latitude: 37.42, longitude: -122.08)) }
      end
    end

    context 'without places at the address' do
      let(:query) { AddressQuery.new(address_lines: ['1 Main St'], postal_code: '94043', region_code: 'US') }

      it { expect(provider.call).to(be_nil) }
    end
  end

  describe '#supports?' do
    it { is_expected.to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(address_lines: ['1 Main St'], region_code: 'US'))).not_to(be_supports) }
    it { expect(described_class.new(Location.new(latitude: 0, longitude: 0))).not_to(be_supports) }

    context 'without the file' do
      before { allow(Overture::Place).to(receive(:available?).and_return(false)) }

      it { is_expected.not_to(be_supports) }
    end
  end
end
