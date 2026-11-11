require 'rails_helper'

RSpec.describe(AddressResult) do
  subject(:result) { described_class.new(address:, query:, validations:) }

  let(:address) { build(:address, country:, id: '0193a8f2-7c4e-7b1a-9f3d-2e5c8b6a4d10') }

  let(:country) { build(:country, iso3166_1_alpha2: 'US', name: 'United States') }
  let(:query) do
    AddressQuery.new(address_lines: ['1600 amphitheatre parkway'], locality: 'Mtn View', postal_code: '94043', region_code: 'US')
  end
  let(:smarty) do
    build(
      :validation,
      address_lines: ['1600 Amphitheatre Pkwy'],
      administrative_area: 'CA',
      business: true,
      dpv_confirmation: 'Y',
      geocode_granularity: 'PREMISE',
      latitude: 37.42241,
      locality: 'Mountain View',
      longitude: -122.08561,
      po_box: false,
      postal_code: '94043-1351',
      raw: { 'delivery_line_1' => '1600 Amphitheatre Pkwy' },
      residential: false,
      time_zone: 'America/Los_Angeles',
      validation_granularity: 'PREMISE'
    )
  end
  let(:validations) { [smarty] }

  context 'with a confirmed validation' do
    it { is_expected.to(be_address_complete) }
    it { is_expected.to(be_inferred_components) }
    it { is_expected.to(be_replaced_components) }
    it { is_expected.not_to(be_unconfirmed_components) }

    it do
      expect(result).to(
        have_attributes(
          address_id: '0193a8f2-7c4e-7b1a-9f3d-2e5c8b6a4d10',
          address_lines: ['1600 Amphitheatre Pkwy'],
          administrative_area: 'CA',
          business: true,
          formatted_address: '1600 Amphitheatre Pkwy, Mountain View, CA 94043-1351, USA',
          geocode: smarty,
          geocode_granularity: 'PREMISE',
          input_granularity: 'PREMISE',
          locality: 'Mountain View',
          po_box: false,
          postal_code: '94043-1351',
          region_code: 'US',
          residential: false,
          smarty_street_address: { delivery_line_1: '1600 Amphitheatre Pkwy' },
          smarty_zip_code: nil,
          validation: smarty,
          validation_granularity: 'PREMISE'
        )
      )
    end
  end

  context 'with dock answers' do
    let(:validations) { [smarty, build(:validation, dock: false), build(:validation, dock: true)] }

    it { expect(result.dock).to(be(true)) }
  end

  context 'with only an answer without a dock' do
    let(:validations) { [smarty, build(:validation, dock: false)] }

    it { expect(result.dock).to(be(false)) }
  end

  context 'with a time zone' do
    it { expect(result.time_zone).to(have_attributes(expires_at: smarty.expires_at, name: 'America/Los_Angeles', provider: 'smarty')) }
  end

  context 'with an unconfirmed secondary number' do
    before { smarty.dpv_confirmation = 'D' }

    it { is_expected.not_to(be_address_complete) }
    it { is_expected.to(be_unconfirmed_components) }
  end

  context 'with a verification from a postal operator' do
    before do
      smarty.dpv_confirmation = nil
      allow(smarty).to(receive(:authority).and_return(:postal_operator))
    end

    it { is_expected.to(be_address_complete) }
  end

  context 'with a verification from a government' do
    before do
      smarty.dpv_confirmation = nil
      allow(smarty).to(receive(:authority).and_return(:government))
    end

    it { is_expected.to(be_address_complete) }
  end

  context 'with a verification from open data' do
    before do
      smarty.dpv_confirmation = nil
      allow(smarty).to(receive(:authority).and_return(:open_data))
    end

    it { is_expected.not_to(be_address_complete) }
  end

  context 'without validations' do
    let(:validations) { [] }

    it { is_expected.not_to(be_address_complete) }
    it { is_expected.not_to(be_inferred_components) }
    it { is_expected.not_to(be_replaced_components) }
    it { is_expected.to(be_unconfirmed_components) }

    it do
      expect(result).to(
        have_attributes(
          address_lines: ['1600 AMPHITHEATRE PKWY'],
          authority: AuthorityRange.new(highest: :local, lowest: :local),
          business: nil,
          expires_at: nil,
          formatted_address: '1600 AMPHITHEATRE PKWY, MTN VIEW, 94043, USA',
          geocode: nil,
          geocode_granularity: 'OTHER',
          postal_code: '94043',
          smarty_street_address: nil,
          time_zone: nil,
          validation_granularity: 'OTHER'
        )
      )
    end
  end

  context 'with a Smarty ZIP code validation' do
    before { smarty.raw = { 'zipcodes' => [{ 'zipcode' => '94043' }] } }

    it { expect(result).to(have_attributes(smarty_street_address: nil, smarty_zip_code: { zipcodes: [{ zipcode: '94043' }] })) }
  end

  context 'with a geocode-only validation' do
    let(:validations) { [build(:validation, latitude: 1, longitude: 2, provider: 'open_street_map')] }

    it { expect(result).to(have_attributes(geocode: validations.first, smarty_street_address: nil, validation: nil)) }
  end

  context 'with a geocode from a lower authority than the verification' do
    let(:geo_names) { build(:validation, geocode_granularity: 'PREMISE', latitude: 44, longitude: -121, provider: 'geo_names') }
    let(:validations) { [smarty.tap { it.assign_attributes(latitude: nil, longitude: nil) }, geo_names] }

    it { expect(result).to(have_attributes(authority: AuthorityRange.new(highest: :certified, lowest: :certified), geocode: geo_names)) }
    it { expect(result.location.authority).to(eq(:open_data)) }
  end

  context 'with a geocode but no verification' do
    let(:validations) { [build(:validation, latitude: 1, longitude: 2, provider: 'open_street_map')] }

    it { expect(result).to(have_attributes(authority: AuthorityRange.new(highest: :local, lowest: :local))) }
  end

  context 'with a verification without address lines' do
    let(:validations) do
      [build(:validation, address_lines: [], locality: 'Mountain View', provider: 'overture', validation_granularity: 'PREMISE')]
    end

    it { expect(result.address_lines).to(eq(['1600 AMPHITHEATRE PKWY'])) }
    it { expect(result.authority).to(eq(AuthorityRange.new(highest: :open_data, lowest: :local))) }
  end

  context 'with a more precise geocode from a lower authority' do
    let(:overture) { build(:validation, geocode_granularity: 'PREMISE_PROXIMITY', latitude: 37.4, longitude: -122, provider: 'overture') }
    let(:google) { build(:validation, geocode_granularity: 'PREMISE', latitude: 37.42, longitude: -122.08, provider: 'google') }
    let(:validations) { [overture, google] }

    it { expect(result.geocode).to(eq(google)) }
    it { expect(result.location).to(have_attributes(authority: :commercial, granularity: 'PREMISE', latitude: 37.42)) }
  end

  context 'with geocodes of the same precision' do
    let(:open_street_map) do
      build(:validation, geocode_granularity: 'PREMISE', latitude: 37.4, longitude: -122, provider: 'open_street_map')
    end
    let(:google) { build(:validation, geocode_granularity: 'PREMISE', latitude: 37.42, longitude: -122.08, provider: 'google') }
    let(:validations) { [open_street_map, google] }

    it { expect(result.geocode).to(eq(open_street_map)) }
  end

  context 'with a region outside the US' do
    let(:country) { build(:country, iso3166_1_alpha2: 'GB', name: 'United Kingdom') }
    let(:query) { AddressQuery.new(address_lines: ['10 Downing St'], locality: 'London', postal_code: 'SW1A 2AA', region_code: 'GB') }
    let(:validations) { [] }

    it { expect(result.formatted_address).to(eq('10 DOWNING ST, LONDON, SW1A 2AA, United Kingdom')) }
  end

  context 'with a ZIP+4 added to the input ZIP' do
    let(:query) do
      AddressQuery.new(
        address_lines: ['1600 Amphitheatre Pkwy'],
        administrative_area: 'ca',
        locality: 'mountain view',
        postal_code: '94043',
        region_code: 'US'
      )
    end

    it { is_expected.not_to(be_replaced_components) }
  end
end
