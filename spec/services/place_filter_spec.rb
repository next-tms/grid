require 'rails_helper'

RSpec.describe(PlaceFilter) do
  subject(:search) { described_class.new(filter: { name_eq: 'Open Cafe' }, providers:) }

  let(:providers) { [Providers::Fake, Providers::Overture] }

  before do
    create(:overture_place, id: 'overture-1')
    create(:overture_place, id: 'overture-2', name: 'Closed Cafe')
  end

  describe '#provider' do
    it { expect(search.provider).to(eq(Providers::Overture)) }

    context 'without the places file' do
      before { allow(Overture::Place).to(receive(:available?).and_return(false)) }

      it { expect(search.provider).to(be_nil) }
    end

    context 'without a provider that searches places' do
      let(:providers) { [Providers::Fake] }

      it { expect(search.provider).to(be_nil) }
    end
  end

  describe '#call' do
    it { expect(search.call.map(&:id)).to(eq(['overture-1'])) }

    context 'without a provider that searches places' do
      let(:providers) { [Providers::Fake] }

      it { expect(search.call).to(be_nil) }
    end
  end
end
