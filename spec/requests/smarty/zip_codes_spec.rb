require 'rails_helper'

RSpec.describe('Smarty ZIP codes') do
  let(:zipcode) { '94043' }

  before do
    create(:country, iso3166_1_alpha2: 'US')
    allow(Providers).to(receive(:enabled).and_return(providers))
  end

  describe 'GET /lookup' do
    context 'with the fake provider' do
      let(:providers) { [Providers::Fake] }

      before { get('/lookup', params: { 'auth-id' => 'ignored', 'auth-token' => 'ignored', zipcode: }) }

      it { expect(response).to(have_http_status(:ok)) }

      it_behaves_like('a cacheable response')

      it do
        expect(json).to(
          eq(
            [
              {
                city_states: [{ city: 'Los Angeles', mailable_city: true, state_abbreviation: 'CA' }],
                input_index: 0,
                zipcodes: [
                  {
                    default_city: 'Los Angeles',
                    latitude: 34.05224,
                    longitude: -118.24368,
                    precision: 'Zip5',
                    state_abbreviation: 'CA',
                    zipcode: '94043'
                  }
                ]
              }
            ]
          )
        )
      end

      context 'without providers' do
        let(:providers) { [] }

        it { expect(json).to(eq([{ input_index: 0, reason: 'Invalid ZIP Code.', status: 'invalid_zipcode' }])) }
        it { expect(response.headers['Cache-Control']).to(eq('max-age=0, private, must-revalidate')) }
      end

      context 'without a ZIP code' do
        let(:zipcode) { nil }

        it { expect(json.first[:status]).to(eq('blank')) }
      end
    end

    context 'with Smarty' do
      let(:fixture) { Rails.root.join('spec/fixtures/smarty/zip_code.json').read }
      let(:providers) { [Providers::Smarty] }

      before do
        allow(ENV).to(receive(:fetch).and_call_original)
        allow(ENV).to(receive(:fetch).with('SMARTY_AUTH_ID').and_return('id'))
        allow(ENV).to(receive(:fetch).with('SMARTY_AUTH_TOKEN').and_return('token'))
        stub_request(:get, /us-zipcode\.api\.smarty\.com/).to_return(body: fixture)
        get('/lookup', params: { zipcode: })
      end

      it { expect(json).to(eq(JSON.parse(fixture, symbolize_names: true))) }
    end
  end
end
