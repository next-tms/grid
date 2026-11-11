require 'rails_helper'

RSpec.describe(Providers) do
  describe '.all' do
    it do
      expect(described_class.all).to(
        include(Providers::GeoNames, Providers::Google, Providers::OpenStreetMap, Providers::Overture, Providers::Smarty)
      )
    end
  end

  describe '.enabled' do
    let(:credentials) do
      { 'GEONAMES_USERNAME' => 'grid', 'GOOGLE_API_KEY' => 'key', 'SMARTY_AUTH_ID' => 'id', 'SMARTY_AUTH_TOKEN' => 'token' }
    end

    before do
      allow(ENV).to(receive(:[]).and_call_original)
      credentials.each { |key, value| allow(ENV).to(receive(:[]).with(key).and_return(value)) }
      allow(ENV).to(receive(:fetch).with('GRID_PROVIDERS', '').and_return(providers))
    end

    context 'with known and unknown keys' do
      let(:providers) { ' smarty , unknown,,' }

      it { expect(described_class.enabled).to(eq([Providers::Smarty])) }
    end

    context 'with providers out of authority order' do
      let(:providers) { 'geo_names,fake,smarty' }

      it { expect(described_class.enabled).to(eq([Providers::Smarty, Providers::GeoNames, Providers::Fake])) }
    end

    context 'with providers of the same authority' do
      let(:providers) { 'google,fake' }

      it { expect(described_class.enabled).to(eq([Providers::Fake, Providers::Google])) }
    end

    context 'without the credentials of a provider' do
      let(:credentials) { { 'SMARTY_AUTH_ID' => 'id' } }
      let(:providers) { 'smarty,fake' }

      before do
        described_class.unconfigured.clear
        allow(Rails.logger).to(receive(:warn))
      end

      it { expect(described_class.enabled).to(eq([Providers::Fake])) }

      it do
        2.times { described_class.enabled }

        expect(Rails.logger).to(have_received(:warn).with('smarty is disabled because SMARTY_AUTH_ID or SMARTY_AUTH_TOKEN is not set').once)
      end
    end

    context 'without GRID_PROVIDERS' do
      let(:providers) { '' }

      it { expect(described_class.enabled).to(eq([])) }
    end
  end

  describe '.find' do
    it { expect(described_class.find('smarty')).to(eq(Providers::Smarty)) }
    it { expect(described_class.find('unknown')).to(be_nil) }
  end
end
