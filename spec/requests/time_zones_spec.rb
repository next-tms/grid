require 'rails_helper'

RSpec.describe('Time zones') do
  let(:location) { '37.42241,-122.08561' }
  let(:providers) { [Providers::Fake] }
  let(:timestamp) { Time.utc(2026, 7, 1).to_i }

  before do
    freeze_time
    allow(Providers).to(receive(:enabled).and_return(providers))
    get('/maps/api/timezone/json', params: { key: 'ignored', location:, timestamp: }.compact)
  end

  describe 'GET /maps/api/timezone/json' do
    it { expect(response).to(have_http_status(:ok)) }

    it_behaves_like('a cacheable response')

    context 'when daylight saving time' do
      it do
        expect(json).to(
          eq(
            dst_offset: 3600,
            raw_offset: -28_800,
            status: 'OK',
            time_zone_id: 'America/Los_Angeles',
            time_zone_name: 'PDT'
          )
        )
      end
    end

    context 'when standard time' do
      let(:timestamp) { Time.utc(2026, 1, 1).to_i }

      it { expect(json).to(include(dst_offset: 0, time_zone_name: 'PST')) }
    end

    context 'without time zone providers' do
      let(:providers) { [] }

      it { expect(json).to(eq(status: 'ZERO_RESULTS')) }
    end

    context 'with an invalid location' do
      let(:location) { '91,0' }

      it { expect(json).to(eq(error_message: "Invalid request. Invalid 'location' parameter.", status: 'INVALID_REQUEST')) }
    end

    context 'without a timestamp' do
      let(:timestamp) { nil }

      it { expect(json).to(eq(error_message: "Invalid request. Invalid 'timestamp' parameter.", status: 'INVALID_REQUEST')) }
    end

    context 'when the provider fails' do
      let(:adapter) { instance_double(Providers::Fake, supports?: true) }
      let(:providers) { [Providers::Fake] }

      before do
        allow(adapter).to(receive(:time_zone_name).and_raise(Providers::Error, 'down'))
        allow(Providers::Fake).to(receive(:new).and_return(adapter))
        allow(Sentry).to(receive(:capture_exception))
        get('/maps/api/timezone/json', params: { location:, timestamp: })
      end

      it { expect(json).to(eq(error_message: 'down', status: 'UNKNOWN_ERROR')) }
      it { expect(Sentry).to(have_received(:capture_exception).with(instance_of(Providers::Error))) }
    end
  end
end
