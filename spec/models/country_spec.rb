require 'rails_helper'

RSpec.describe(Country) do
  subject(:country) { build(:country, iso3166_1_alpha2: 'US') }

  describe '#region_code' do
    it { expect(country.region_code).to(eq('US')) }
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:addresses).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:administrative_areas).dependent(:destroy)) }
    it { is_expected.to(have_many(:localities).through(:administrative_areas)) }
    it { is_expected.to(have_many(:postal_codes).dependent(:destroy)) }
    it { is_expected.to(have_many(:provider_identifiers).dependent(:destroy)) }
  end

  describe 'validations' do
    it { is_expected.to(allow_value('US').for(:iso3166_1_alpha2)) }
    it { is_expected.not_to(allow_value('us', 'USA').for(:iso3166_1_alpha2)) }
    it { is_expected.to(allow_value('USA').for(:iso3166_1_alpha3)) }
    it { is_expected.not_to(allow_value('usa', 'US').for(:iso3166_1_alpha3)) }
    it { is_expected.to(validate_numericality_of(:un_m49).only_integer.is_in(1..999)) }
    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_uniqueness_of(:iso3166_1_alpha2)) }
    it { is_expected.to(validate_uniqueness_of(:iso3166_1_alpha3)) }
    it { is_expected.to(validate_uniqueness_of(:un_m49)) }
  end
end
