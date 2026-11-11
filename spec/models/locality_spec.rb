require 'rails_helper'

RSpec.describe(Locality) do
  subject(:locality) { build(:locality) }

  describe '#country' do
    it { expect(locality.country).to(eq(locality.administrative_area.country)) }
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:administrative_area)) }
    it { is_expected.to(have_many(:addresses).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:postal_codes).dependent(:nullify)) }
    it { is_expected.to(have_many(:provider_identifiers).dependent(:destroy)) }
  end

  describe 'validations' do
    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_uniqueness_of(:name).scoped_to(:administrative_area_id)) }
  end
end
