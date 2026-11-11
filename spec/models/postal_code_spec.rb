require 'rails_helper'

RSpec.describe(PostalCode) do
  subject(:postal_code) { build(:postal_code, locality: nil) }

  describe 'callbacks' do
    subject(:postal_code) { build(:postal_code, country: nil) }

    before { postal_code.validate }

    it { expect(postal_code.country).to(eq(postal_code.locality.country)) }
  end

  describe 'normalizations' do
    it { is_expected.to(normalize(:value).from(' sw1a  1aa ').to('SW1A 1AA')) }
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:country)) }
    it { is_expected.to(belong_to(:locality).optional) }
    it { is_expected.to(have_many(:addresses).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:provider_identifiers).dependent(:destroy)) }
  end

  describe 'validations' do
    it { is_expected.to(be_valid) }
    it { is_expected.to(validate_presence_of(:value)) }
    it { is_expected.to(validate_uniqueness_of(:value).scoped_to(:country_id).ignoring_case_sensitivity) }

    context 'with a locality' do
      subject(:postal_code) { build(:postal_code) }

      it { is_expected.to(be_valid) }
    end

    context 'with a locality in another country' do
      subject(:postal_code) { build(:postal_code, country: create(:country)) }

      it { is_expected.not_to(be_valid) }
    end
  end
end
