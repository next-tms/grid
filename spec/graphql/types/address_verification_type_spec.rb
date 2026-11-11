require 'rails_helper'

RSpec.describe(Types::AddressVerificationType) do
  subject(:address_verification) { execute(query, address:).dig(:data, :verify_address) }

  let(:address) { { addressLines: ['1600 Amphitheatre Pkwy'], regionCode: 'US' } }
  let(:providers) { [Providers::Fake] }

  before do
    create(:country, iso3166_1_alpha2: 'US')
    allow(Providers).to(receive(:enabled).and_return(providers))
  end

  describe 'fingerprint' do
    let(:query) { 'query($address: AddressInput!) { verifyAddress(address: $address) { fingerprint } }' }

    it { expect(address_verification).to(eq(fingerprint: Fingerprint.of(Validation.where(provider: 'fake').to_a))) }
  end

  describe 'location' do
    let(:location) do
      { authority: 'COMMERCIAL', granularity: 'PREMISE', latitude: 37.42241, longitude: -122.08561, plus_code: '849VCWC7+XQ' }
    end
    let(:query) do
      <<~GRAPHQL
        query($address: AddressInput!) {
          verifyAddress(address: $address) { location { authority granularity latitude longitude plusCode } }
        }
      GRAPHQL
    end

    it { expect(address_verification).to(eq(location:)) }
  end

  describe 'places' do
    let(:query) { 'query($address: AddressInput!) { verifyAddress(address: $address) { places { name } } }' }

    it { expect(address_verification).to(eq(places: [{ name: 'Fake Cafe' }, { name: 'Fake Office' }])) }
  end

  describe 'timeZone' do
    let(:query) { 'query($address: AddressInput!) { verifyAddress(address: $address) { timeZone { id } } }' }

    before { allow(TimeZoneLookup).to(receive(:new).and_call_original) }

    it { expect(address_verification).to(eq(time_zone: { id: 'America/Los_Angeles' })) }

    it do
      address_verification

      expect(TimeZoneLookup).not_to(have_received(:new))
    end

    context 'without a time zone in the verification' do
      let(:address) { { postalCode: '90012', regionCode: 'US' } }

      it { expect(address_verification).to(eq(time_zone: { id: 'America/Los_Angeles' })) }

      it do
        address_verification

        expect(TimeZoneLookup).to(have_received(:new))
      end
    end
  end
end
