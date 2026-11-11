require 'rails_helper'

RSpec.describe(Types::AddressVerificationType) do
  subject(:address_verification) { execute(query, address:).dig(:data, :verify_address) }

  let(:address) { { addressLines: ['1600 Amphitheatre Pkwy'], regionCode: 'US' } }
  let(:providers) { [Providers::Fake] }

  before do
    create(:country, iso3166_1_alpha2: 'US')
    allow(Providers).to(receive(:enabled).and_return(providers))
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

    it { expect(address_verification).to(eq(time_zone: { id: 'America/Los_Angeles' })) }

    it do
      address_verification

      expect(sources.grep(TimeZone)).to(be_empty)
    end

    context 'without a time zone in the verification' do
      let(:address) { { postalCode: '90012', regionCode: 'US' } }

      it do
        address_verification

        expect(sources.grep(TimeZone)).to(contain_exactly(have_attributes(name: 'America/Los_Angeles')))
      end
    end
  end
end
