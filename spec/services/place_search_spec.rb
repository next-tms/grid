require 'rails_helper'

RSpec.describe(PlaceSearch) do
  subject(:search) { described_class.new(address, providers:) }

  let(:address) { create(:address) }
  let(:providers) { [Providers::Fake] }

  describe '#call' do
    it { expect(search.call.map(&:name)).to(eq(['Fake Cafe', 'Fake Office'])) }

    it do
      search.call

      expect(search.sources).to(contain_exactly(have_attributes(provider: 'fake')))
    end

    context 'without places' do
      before { create(:validation, provider: 'fake', validatable: address) }

      it { expect(search.call).to(be_empty) }
    end

    context 'with a residential address' do
      before do
        allow(Providers).to(receive(:enabled).and_return([Providers::Smarty]))
        create(:validation, residential: true, validatable: address)
      end

      it { expect(search.call).to(be_empty) }
    end

    context 'with open data and Google' do
      let(:providers) { [Providers::Overture, Providers::Google] }
      let(:address) { create(:address, address_lines: ['1600 AMPHITHEATRE PKWY']).tap { it.postal_code.update!(value: '94043') } }
      let!(:google) { stub_request(:post, Providers::Google::SEARCH_ENDPOINT.to_s).to_return(body: '{}') }

      before do
        allow(ENV).to(receive(:fetch).and_call_original)
        allow(ENV).to(receive(:fetch).with('GOOGLE_API_KEY').and_return('key'))
        create(:overture_place, address_key: AddressKey.for(address.query))
      end

      it { expect(search.call.map(&:name)).to(eq(['Open Cafe'])) }

      it do
        search.call

        expect(google).not_to(have_been_requested)
      end
    end

    context 'with a provider without a business details role' do
      let(:providers) { [Providers::Smarty] }

      it { expect(search.providers).to(be_empty) }
    end
  end
end
