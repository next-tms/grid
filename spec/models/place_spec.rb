require 'rails_helper'

RSpec.describe(Place) do
  subject(:place) { build(:place) }

  describe 'id' do
    it { expect(create(:place).id).to(match(/\A\h{8}-\h{4}-7\h{3}-\h{4}-\h{12}\z/)) }
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:address)) }
    it { is_expected.to(belong_to(:validation)) }
    it { is_expected.to(have_many(:provider_identifiers).dependent(:destroy)) }
  end

  describe 'validations' do
    it { is_expected.to(be_valid) }
    it { is_expected.to(validate_presence_of(:name)) }

    context 'with a provider that must not store content' do
      subject(:place) { build(:place, name: nil, validation: build(:validation, provider: 'google')) }

      it { is_expected.to(be_valid) }
    end
  end

  describe 'delegations' do
    it { expect(place).to(have_attributes(authority: :certified, expires_at: place.validation.expires_at)) }
    it { expect(place).to(have_attributes(fetched_at: place.validation.fetched_at, provider: place.validation.provider)) }
  end
end
