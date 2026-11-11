require 'rails_helper'

RSpec.describe(Smarty::ZIPCodeLookup) do
  subject(:lookup) { described_class.new(zipcode:) }

  let(:providers) { [Providers::Fake] }
  let(:zipcode) { ' 94043 ' }

  before do
    create(:country, iso3166_1_alpha2: 'US')
    allow(Providers).to(receive(:enabled).and_return(providers))
  end

  describe '#query' do
    it { expect(lookup.query).to(have_attributes(postal_code: '94043', region_code: 'US')) }
    it { expect(described_class.new(zipcode: '94043-1351').query.postal_code).to(eq('94043')) }
  end

  describe '#status' do
    it { expect(lookup).to(have_attributes(reason: nil, status: nil)) }

    context 'without a ZIP code' do
      let(:zipcode) { ' ' }

      it { expect(lookup).to(have_attributes(reason: start_with('Blank lookup'), status: 'blank')) }
    end

    context 'with a malformed ZIP code' do
      let(:zipcode) { '9404' }

      it { expect(lookup).to(have_attributes(reason: 'Invalid ZIP Code.', status: 'invalid_zipcode')) }
    end

    context 'without a match' do
      let(:providers) { [] }

      it { expect(lookup.status).to(eq('invalid_zipcode')) }
    end
  end
end
