require 'rails_helper'

RSpec.describe(Providers::Base) do
  subject(:provider) { provider_class.new(AddressQuery.new) }

  let(:provider_class) do
    Class.new(described_class) do
      class << self
        def cache_duration = 1.day
        def name = 'Providers::Example'
      end

      def fetch(uri) = get_json(uri)
      def send_json(uri, body, headers = {}) = post_json(uri, body, headers)
      def validation(**) = build_validation(**)
    end
  end
  let(:uri) { URI('https://example.test/lookup?q=1') }

  describe '.configured?' do
    it { expect(provider_class).to(be_configured) }
  end

  describe '.credential_keys' do
    it { expect(provider_class.credential_keys).to(eq([])) }
  end

  describe '.key' do
    it { expect(provider_class.key).to(eq('example')) }
  end

  describe '.stores_content?' do
    it { expect(provider_class.stores_content?).to(be(true)) }
  end

  describe 'abstract methods' do
    it { expect { described_class.authority }.to(raise_error(NotImplementedError)) }
    it { expect { described_class.cache_duration }.to(raise_error(NotImplementedError)) }
    it { expect { described_class.cost }.to(raise_error(NotImplementedError)) }
    it { expect { described_class.roles }.to(raise_error(NotImplementedError)) }
    it { expect { described_class.new(AddressQuery.new).call }.to(raise_error(NotImplementedError)) }
    it { expect { described_class.new(AddressQuery.new).supports? }.to(raise_error(NotImplementedError)) }
    it { expect { described_class.new(AddressQuery.new).time_zone_name }.to(raise_error(NotImplementedError)) }
  end

  describe '#build_validation' do
    let(:validation) { provider.validation(locality: 'Mountain View') }

    before { freeze_time }

    it { expect(validation).to(be_new_record) }

    it do
      expect(validation)
        .to(
          have_attributes(
            expires_at: 1.day.from_now,
            fetched_at: Time.current,
            locality: 'Mountain View',
            provider: 'example'
          )
        )
    end
  end

  describe '#post_json' do
    before { stub_request(:post, uri).with(body: '{"a":1}', headers: { 'Content-Type' => 'application/json' }).to_return(body: '{"b":2}') }

    it { expect(provider.send_json(uri, { a: 1 })).to(eq(b: 2)) }

    context 'with headers' do
      before { stub_request(:post, uri).with(headers: { 'Content-Type' => 'application/json', 'X-Key' => 'k' }).to_return(body: '{"c":3}') }

      it { expect(provider.send_json(uri, { a: 1 }, 'X-Key' => 'k')).to(eq(c: 3)) }
    end
  end

  describe '#get_json' do
    context 'when the provider responds with JSON' do
      before { stub_request(:get, uri).to_return(body: '[{"a":1}]') }

      it { expect(provider.fetch(uri)).to(eq([{ a: 1 }])) }
    end

    context 'when the provider responds with an error status' do
      before { stub_request(:get, uri).to_return(status: 401, body: 'Unauthorized') }

      it { expect { provider.fetch(uri) }.to(raise_error(Providers::Error, 'example responded 401: Unauthorized')) }
    end

    context 'when the provider responds with invalid JSON' do
      before { stub_request(:get, uri).to_return(body: '<html>') }

      it { expect { provider.fetch(uri) }.to(raise_error(Providers::Error, /example failed/)) }
    end

    context 'when the provider times out' do
      before { stub_request(:get, uri).to_timeout }

      it { expect { provider.fetch(uri) }.to(raise_error(Providers::Error, /example failed/)) }
    end

    context 'when the connection is refused' do
      before { stub_request(:get, uri).to_raise(Errno::ECONNREFUSED) }

      it { expect { provider.fetch(uri) }.to(raise_error(Providers::Error, /example failed/)) }
    end
  end
end
