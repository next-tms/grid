require 'rails_helper'

RSpec.describe('Smarty street addresses') do
  let(:fixture) { Rails.root.join('spec/fixtures/smarty/street_address.json').read }
  let(:params) do
    {
      'auth-id' => 'ignored',
      'auth-token' => 'ignored',
      candidates: 1,
      city: 'Mountain View',
      state: 'CA',
      street: '1600 Amphitheatre Pkwy',
      zipcode: '94043'
    }
  end

  before do
    create(:country, iso3166_1_alpha2: 'US')
    allow(Providers).to(receive(:enabled).and_return(providers))
  end

  describe 'GET /street-address' do
    context 'with the fake provider' do
      let(:providers) { [Providers::Fake] }

      before { get('/street-address', params:) }

      it { expect(response).to(have_http_status(:ok)) }

      it_behaves_like('a cacheable response')

      it do
        expect(json).to(
          eq(
            [
              {
                analysis: { dpv_match_code: 'Y' },
                candidate_index: 0,
                components: { city_name: 'Mountain View', state_abbreviation: 'CA', zipcode: '94043' },
                delivery_line_1: '1600 Amphitheatre Pkwy',
                input_index: 0,
                last_line: 'Mountain View CA 94043',
                metadata: { latitude: 37.42241, longitude: -122.08561, precision: 'Rooftop', rdi: 'Commercial' }
              }
            ]
          )
        )
      end

      context 'without providers' do
        let(:providers) { [] }

        it { expect(json).to(eq([])) }
      end

      context 'without a street' do
        let(:params) { { city: 'Mountain View' } }

        it { expect(response).to(have_http_status(:bad_request)) }
      end
    end

    context 'with Smarty' do
      let(:providers) { [Providers::Smarty] }

      before do
        allow(ENV).to(receive(:fetch).and_call_original)
        allow(ENV).to(receive(:fetch).with('SMARTY_AUTH_ID').and_return('id'))
        allow(ENV).to(receive(:fetch).with('SMARTY_AUTH_TOKEN').and_return('token'))
        stub_request(:get, /us-street\.api\.smarty\.com/).to_return(body: fixture)
        get('/street-address', params: params.merge(input_id: 'abc'))
      end

      it { expect(json).to(eq([JSON.parse(fixture, symbolize_names: true).first.merge(input_id: 'abc')])) }
    end
  end
end
