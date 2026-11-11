require 'rails_helper'

RSpec.describe(Providers::Smarty) do
  subject(:provider) { described_class.new(query) }

  let(:body) { Rails.root.join('spec/fixtures/smarty/street_address.json').read }
  let(:candidate) { JSON.parse(body, symbolize_names: true).first }
  let(:query) do
    AddressQuery.new(
      address_lines: ['1600 Amphitheatre Parkway', 'Bldg 40'],
      administrative_area: 'CA',
      locality: 'Mountain View',
      organization: 'Google',
      postal_code: '94043',
      region_code: 'US'
    )
  end
  let(:request) do
    stub_request(:get, described_class::STREET_ENDPOINT.to_s).with(
      query: {
        'addressee' => 'Google',
        'auth-id' => 'id',
        'auth-token' => 'token',
        'candidates' => '1',
        'city' => 'Mountain View',
        'features' => 'iana-timezone',
        'state' => 'CA',
        'street' => '1600 Amphitheatre Parkway',
        'street2' => 'Bldg 40',
        'zipcode' => '94043'
      }
    )
  end

  before do
    allow(ENV).to(receive(:fetch).and_call_original)
    allow(ENV).to(receive(:fetch).with('SMARTY_AUTH_ID').and_return('id'))
    allow(ENV).to(receive(:fetch).with('SMARTY_AUTH_TOKEN').and_return('token'))
  end

  describe '.authority' do
    it { expect(described_class.authority).to(eq(:certified)) }
  end

  describe '.cache_duration' do
    it { expect(described_class.cache_duration).to(eq(90.days)) }
  end

  describe '.cost' do
    it { expect(described_class.cost).to(eq(:low)) }
  end

  describe '.credential_keys' do
    it { expect(described_class.credential_keys).to(eq(['SMARTY_AUTH_ID', 'SMARTY_AUTH_TOKEN'])) }
  end

  describe '.key' do
    it { expect(described_class.key).to(eq('smarty')) }
  end

  describe '.roles' do
    it { expect(described_class.roles).to(eq(%i[geocode time_zone verification])) }
  end

  describe '#call' do
    let(:validation) { provider.call }

    context 'when Smarty finds the address' do
      before { request.to_return(body:) }

      it { expect(validation).to(be_a(Validation).and(be_new_record)) }
      it { expect(validation.provider_identifier).to(be_nil) }

      context 'with a smarty_key' do
        let(:body) { [JSON.parse(super()).first.merge('smarty_key' => '1962995076')].to_json }

        it { expect(validation.provider_identifier).to(eq('1962995076')) }
      end

      it do
        expect(validation).to(
          have_attributes(
            address_lines: ['1600 Amphitheatre Pkwy'],
            administrative_area: 'CA',
            business: true,
            dpv_confirmation: 'Y',
            geocode_granularity: 'PREMISE',
            latitude: BigDecimal('37.42241'),
            locality: 'Mountain View',
            longitude: BigDecimal('-122.08561'),
            po_box: false,
            postal_code: '94043-1351',
            provider: 'smarty',
            raw: candidate,
            region_code: 'US',
            residential: false,
            time_zone: 'America/Los_Angeles',
            validation_granularity: 'PREMISE'
          )
        )
      end

      it do
        freeze_time
        expect(validation.expires_at).to(eq(90.days.from_now))
      end
    end

    context 'when Smarty finds no address' do
      before { request.to_return(body: '[]') }

      it { expect(validation).to(be_nil) }
    end

    context 'when Smarty rejects the credentials' do
      before { request.to_return(status: 401, body: 'Unauthorized') }

      it { expect { validation }.to(raise_error(Providers::Error, 'smarty responded 401: Unauthorized')) }
    end

    context 'with a confirmed secondary number' do
      before { request.to_return(body: [candidate.deep_merge(components: { secondary_number: '4' })].to_json) }

      it { expect(validation.validation_granularity).to(eq('SUB_PREMISE')) }
    end

    context 'with a missing or unconfirmed secondary number' do
      ['D', 'S'].each do |dpv_match_code|
        before { request.to_return(body: [candidate.deep_merge(analysis: { dpv_match_code: })].to_json) }

        it { expect(validation.validation_granularity).to(eq('PREMISE')) }
      end
    end

    context 'without delivery point confirmation' do
      before { request.to_return(body: [candidate.deep_merge(analysis: { dpv_match_code: '' })].to_json) }

      it { expect(validation).to(have_attributes(dpv_confirmation: nil, validation_granularity: 'ROUTE')) }
    end

    context 'with a residential delivery point' do
      before { request.to_return(body: [candidate.deep_merge(metadata: { rdi: 'Residential' })].to_json) }

      it { expect(validation).to(have_attributes(business: false, residential: true)) }
    end

    context 'without RDI' do
      before { request.to_return(body: [candidate.deep_merge(metadata: { rdi: '' })].to_json) }

      it { expect(validation).to(have_attributes(business: nil, residential: nil)) }
    end

    context 'with an unknown time zone' do
      before { request.to_return(body: [candidate.deep_merge(metadata: { iana_time_zone: 'Mars/Olympus_Mons' })].to_json) }

      it { expect(validation.time_zone).to(be_nil) }
    end

    context 'with a PO box' do
      before { request.to_return(body: [candidate.deep_merge(metadata: { record_type: 'P' })].to_json) }

      it { expect(validation.po_box).to(be(true)) }
    end

    context 'with a ZIP+4 centroid' do
      before { request.to_return(body: [candidate.deep_merge(metadata: { precision: 'Zip9' })].to_json) }

      it { expect(validation.geocode_granularity).to(eq('BLOCK')) }
    end

    context 'with an unknown precision' do
      before { request.to_return(body: [candidate.deep_merge(metadata: { precision: 'Unknown' })].to_json) }

      it { expect(validation.geocode_granularity).to(be_nil) }
    end

    context 'with a Puerto Rico address' do
      let(:query) { AddressQuery.new(address_lines: ['1 Calle Luna'], locality: 'San Juan', region_code: 'PR') }
      let(:request) do
        stub_request(:get, described_class::STREET_ENDPOINT.to_s).with(
          query: {
            'auth-id' => 'id', 'auth-token' => 'token', 'candidates' => '1', 'city' => 'San Juan', 'features' => 'iana-timezone',
            'state' => 'PR', 'street' => '1 Calle Luna'
          }
        )
      end

      before { request.to_return(body: [candidate.deep_merge(components: { state_abbreviation: 'PR' })].to_json) }

      it { expect(validation).to(have_attributes(administrative_area: 'PR', region_code: 'PR')) }
    end

    context 'with only a ZIP code' do
      let(:query) { AddressQuery.new(postal_code: '97701', region_code: 'US') }
      let(:validation) { provider.call }
      let(:zip_code_request) do
        stub_request(:get, described_class::ZIP_CODE_ENDPOINT.to_s)
          .with(query: { 'auth-id' => 'id', 'auth-token' => 'token', 'zipcode' => '97701' })
      end

      context 'when Smarty knows the ZIP code' do
        before { zip_code_request.to_return(body: Rails.root.join('spec/fixtures/smarty/zip_code.json').read) }

        it do
          expect(validation).to(
            have_attributes(
              administrative_area: 'OR',
              geocode_granularity: 'OTHER',
              latitude: BigDecimal('44.0848'),
              locality: 'Bend',
              longitude: BigDecimal('-121.2969'),
              postal_code: '97701',
              region_code: 'US',
              validation_granularity: 'OTHER'
            )
          )
        end
      end

      context 'when Smarty does not know the ZIP code' do
        before { zip_code_request.to_return(body: [{ input_index: 0, reason: 'Invalid ZIP Code.', status: 'invalid_zipcode' }].to_json) }

        it { expect(validation).to(be_nil) }
      end
    end
  end

  describe '#supports?' do
    it { is_expected.to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(address_lines: ['1 Calle Luna'], region_code: 'PR'))).to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(address_lines: ['10 Downing St'], region_code: 'GB'))).not_to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(postal_code: '94043', region_code: 'US'))).to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(region_code: 'US'))).not_to(be_supports) }
    it { expect(described_class.new(AddressQuery.new(address_lines: ['1600 Amphitheatre Pkwy']))).not_to(be_supports) }
    it { expect(described_class.new(Location.new(latitude: 1, longitude: 2))).not_to(be_supports) }
  end
end
