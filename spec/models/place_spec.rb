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

  describe '#address_lines' do
    it { expect(place.address_lines).to(eq(['1600 Amphitheatre Pkwy'])) }
    it { expect(build(:place, validation: build(:validation, address_lines: [])).address_lines).to(eq(place.address.address_lines)) }
  end

  describe '#administrative_area' do
    it { expect(place.administrative_area).to(eq(place.address.administrative_area.abbreviation)) }
    it { expect(build(:place, validation: build(:validation, administrative_area: 'CA')).administrative_area).to(eq('CA')) }
  end

  describe '#fingerprint_source' do
    it { expect(create(:place).then { it.fingerprint_source == it.validation }).to(be(true)) }
    it { expect(place.fingerprint_source).to(include(place.id, 'Fake Cafe')) }
  end

  describe '#locality' do
    it { expect(place.locality).to(eq(place.address.locality.name)) }
  end

  describe '#location' do
    it { expect(place.location).to(be_nil) }

    context 'with a geocode' do
      subject(:place) { build(:place, validation: build(:validation, geocode_granularity: 'PREMISE', latitude: 37.42, longitude: -122.08)) }

      it { expect(place.location).to(eq(Location.new(authority: :certified, granularity: 'PREMISE', latitude: 37.42, longitude: -122.08))) }
    end
  end

  describe '#postal_code' do
    it { expect(place.postal_code).to(eq(place.address.postal_code.value)) }
  end

  describe '#region_code' do
    it { expect(place.region_code).to(eq('US')) }
  end
end
