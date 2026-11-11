require 'rails_helper'

RSpec.describe(PlaceDetails) do
  subject(:place_details) { described_class.new(address, providers:) }

  let(:address) { create(:address) }
  let(:providers) { [Providers::Fake] }

  describe '#call' do
    it { expect(place_details.call).to(have_attributes(permanently_closed: false, provider: 'fake')) }
    it { expect(place_details.call.types).to(eq(['establishment', 'point_of_interest'])) }

    context 'without business details' do
      before { create(:validation, provider: 'fake', validatable: address) }

      it { expect(place_details.call).to(be_nil) }
    end

    context 'with a provider without a business details role' do
      let(:providers) { [Providers::Smarty] }

      it { expect(place_details.providers).to(be_empty) }
    end
  end
end
