require 'rails_helper'

RSpec.describe('Places') do
  let(:address) { create(:address) }
  let(:field_mask) { 'businessStatus,types' }
  let(:providers) { [Providers::Fake] }

  before do
    allow(Providers).to(receive(:enabled).and_return(providers))
    get("/v1/places/#{place_id}", headers: { 'X-Goog-Api-Key' => 'ignored', 'X-Goog-FieldMask' => field_mask })
  end

  describe 'GET /v1/places/:place_id' do
    context 'with a known place' do
      let(:place_id) { "grid:#{address.id}" }

      it { expect(response).to(have_http_status(:ok)) }

      it_behaves_like('a cacheable response')
      it { expect(response.headers['Vary']).to(eq('X-Goog-FieldMask')) }
      it { expect(json).to(eq(business_status: 'OPERATIONAL', types: ['establishment', 'point_of_interest'])) }

      context 'with the id field' do
        let(:field_mask) { 'id,types' }

        it { expect(json).to(eq(id: "grid:#{address.id}", types: ['establishment', 'point_of_interest'])) }
      end

      context 'with a wildcard field mask' do
        let(:field_mask) { '*' }

        it { expect(json.keys).to(contain_exactly(:business_status, :id, :types)) }
      end

      context 'without a field mask' do
        let(:field_mask) { nil }

        it { expect(response).to(have_http_status(:bad_request)) }
        it { expect(json.dig(:error, :message)).to(eq('FieldMask is a required parameter.')) }
        it { expect(json.dig(:error, :status)).to(eq('INVALID_ARGUMENT')) }
      end

      context 'without business details providers' do
        let(:providers) { [] }

        it { expect(json).to(eq({})) }
      end
    end

    context 'with a permanently closed place' do
      let(:place_id) { "grid:#{address.id}" }
      let(:address) { create(:validation, permanently_closed: true, provider: 'fake', types: ['restaurant']).validatable }

      it { expect(json).to(eq(business_status: 'CLOSED_PERMANENTLY', types: ['restaurant'])) }
    end

    context 'with a stored Google place ID' do
      let(:place_id) { create(:provider_identifier, identifiable: address, provider: 'google', value: 'ChIJj61dQgK6j4AR4GeTYWZsKWw').value }

      it { expect(json).to(eq(business_status: 'OPERATIONAL', types: ['establishment', 'point_of_interest'])) }
    end

    context 'with an unknown Grid place ID' do
      let(:place_id) { 'grid:0193a8f2-7c4e-7b1a-9f3d-2e5c8b6a4d10' }

      it { expect(response).to(have_http_status(:not_found)) }
    end

    context 'with an unknown place' do
      let(:place_id) { 'unknown' }

      it { expect(response).to(have_http_status(:not_found)) }
      it { expect(json).to(eq(error: { code: 404, message: "Place 'unknown' not found.", status: 'NOT_FOUND' })) }
    end
  end
end
