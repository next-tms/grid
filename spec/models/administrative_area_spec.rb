require 'rails_helper'

RSpec.describe(AdministrativeArea) do
  subject(:administrative_area) { build(:administrative_area) }

  describe 'callbacks' do
    let(:country) { create(:country, iso3166_1_alpha2: 'US') }

    before { administrative_area.update!(country: nil, iso3166_2: "#{country.iso3166_1_alpha2}-CA") }

    it { expect(administrative_area.abbreviation).to(eq('CA')) }
    it { expect(administrative_area.country).to(eq(country)) }
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:country)) }
    it { is_expected.to(have_many(:addresses).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:localities).dependent(:destroy)) }
    it { is_expected.to(have_many(:postal_codes).through(:localities)) }
    it { is_expected.to(have_many(:provider_identifiers).dependent(:destroy)) }
  end

  describe 'validations' do
    it { is_expected.to(allow_value(nil, 'US-CA', 'FR-75C').for(:iso3166_2)) }
    it { is_expected.not_to(allow_value('US', 'us-ca', 'USA-CA').for(:iso3166_2)) }
    it { is_expected.to(validate_presence_of(:name)) }
    it { is_expected.to(validate_uniqueness_of(:abbreviation).scoped_to(:country_id).allow_nil) }
    it { is_expected.to(validate_uniqueness_of(:name).scoped_to(:country_id)) }
  end
end
