require 'rails_helper'

RSpec.describe(PlaceResolver) do
  subject(:resolver) { described_class.new(Providers::Overture, Overture::Place.order(:id)) }

  before do
    create(:country, iso3166_1_alpha2: 'US')
    create(:overture_place, freeform: '1600 Amphitheatre Pkwy', id: 'overture-1', name: 'Open Cafe')
    create(:overture_place, address_key: '1 MAIN ST, 94043, US', freeform: '1 Main St', id: 'overture-2', name: 'Main Diner')
  end

  describe '#call' do
    it { expect(resolver.call.map(&:name)).to(eq(['Open Cafe', 'Main Diner'])) }
    it { expect(resolver.call.map(&:id)).to(eq([PlaceId.for('overture', 'overture-1'), PlaceId.for('overture', 'overture-2')])) }
    it { expect(resolver.call.map(&:address)).to(all(be_nil)) }
    it { expect { resolver.call }.not_to(change { [Address.count, Place.count, Validation.count] }) }

    context 'with a stored place' do
      let(:stored) { create(:place, name: 'Old Cafe') }

      before { create(:provider_identifier, identifiable: stored, provider: 'overture', value: 'overture-1') }

      it { expect(resolver.call.first).to(have_attributes(address: stored.address, id: stored.id, name: 'Open Cafe')) }
    end
  end
end
