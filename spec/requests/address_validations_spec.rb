require 'rails_helper'

RSpec.describe('Address validations') do
  let(:address) do
    { addressLines: ['1600 Amphitheatre Pkwy'], administrativeArea: 'CA', locality: 'Mountain View', postalCode: '94043', regionCode: 'US' }
  end

  before do
    create(:country, iso3166_1_alpha2: 'US')
    allow(Providers).to(receive(:enabled).and_return(providers))
  end

  describe 'POST /v1:validateAddress' do
    context 'with the fake provider' do
      let(:providers) { [Providers::Fake] }

      before { post('/v1:validateAddress', as: :json, params: { address: }) }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json.dig(:result, :address, :formatted_address)).to(eq('1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA')) }
      it { expect(json.dig(:result, :geocode, :location)).to(eq(latitude: 37.42241, longitude: -122.08561)) }
      it { expect(json.dig(:result, :geocode, :plus_code)).to(eq(global_code: '849VCWC7+XQ')) }
      it { expect(json.dig(:result, :geocode, :place_id)).to(eq("grid:#{Address.last.id}")) }
      it { expect(json.dig(:result, :metadata)).to(eq(business: true, po_box: false, residential: false)) }
      it { expect(json.dig(:result, :usps_data)).to(be_nil) }
      it { expect(json[:response_id]).to(match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)) }

      it do
        expect(json.dig(:result, :verdict)).to(
          eq(
            address_complete: true,
            geocode_granularity: 'PREMISE',
            input_granularity: 'PREMISE',
            validation_granularity: 'PREMISE'
          )
        )
      end

      it do
        expect(json.dig(:result, :address, :postal_address)).to(
          eq(
            address_lines: ['1600 Amphitheatre Pkwy'],
            administrative_area: 'CA',
            language_code: 'en',
            locality: 'Mountain View',
            postal_code: '94043',
            region_code: 'US'
          )
        )
      end

      context 'without providers' do
        let(:providers) { [] }

        it { expect(json.dig(:result, :geocode)).to(eq(place_id: "grid:#{Address.last.id}")) }
        it { expect(json.dig(:result, :metadata)).to(be_nil) }

        it do
          expect(json.dig(:result, :verdict)).to(
            eq(
              geocode_granularity: 'OTHER',
              has_unconfirmed_components: true,
              input_granularity: 'PREMISE',
              validation_granularity: 'OTHER'
            )
          )
        end
      end
    end

    context 'with Smarty' do
      let(:providers) { [Providers::Smarty] }

      before do
        allow(ENV).to(receive(:fetch).and_call_original)
        allow(ENV).to(receive(:fetch).with('SMARTY_AUTH_ID').and_return('id'))
        allow(ENV).to(receive(:fetch).with('SMARTY_AUTH_TOKEN').and_return('token'))
        stub_request(:get, /us-street\.api\.smarty\.com/).to_return(body: Rails.root.join('spec/fixtures/smarty/street_address.json').read)
        post('/v1:validateAddress', as: :json, params: { address: })
      end

      it do
        expect(json.dig(:result, :usps_data)).to(
          eq(
            carrier_route: 'C909',
            county: 'Santa Clara',
            dpv_cmra: 'N',
            dpv_confirmation: 'Y',
            dpv_footnote: 'AABB',
            dpv_no_stat: 'N',
            dpv_vacant: 'N',
            fips_county_code: '06085',
            standardized_address: {
              city: 'Mountain View',
              city_state_zip_address_line: 'Mountain View CA 94043-1351',
              first_address_line: '1600 Amphitheatre Pkwy',
              state: 'CA',
              zip_code: '94043',
              zip_code_extension: '1351'
            }
          )
        )
      end

      it { expect(json.dig(:result, :address, :postal_address, :postal_code)).to(eq('94043-1351')) }
      it { expect(json.dig(:result, :metadata)).to(eq(business: true, po_box: false, residential: false)) }
    end

    context 'without providers' do
      let(:providers) { [] }

      context 'without an address' do
        before { post('/v1:validateAddress', as: :json, params: {}) }

        it { expect(response).to(have_http_status(:bad_request)) }
        it { expect(json).to(eq(error: { code: 400, message: 'address is required.', status: 'INVALID_ARGUMENT' })) }
      end

      context 'with an unsupported region code' do
        before { post('/v1:validateAddress', as: :json, params: { address: address.merge(regionCode: 'ZZ') }) }

        it { expect(response).to(have_http_status(:bad_request)) }
        it { expect(json).to(eq(error: { code: 400, message: 'Unsupported region code.', status: 'INVALID_ARGUMENT' })) }
      end

      context 'with another method' do
        before { post('/v1:other', as: :json, params: { address: }) }

        it { expect(response).to(have_http_status(:not_found)) }
      end
    end
  end
end
