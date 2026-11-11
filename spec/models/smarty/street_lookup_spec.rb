require 'rails_helper'

RSpec.describe(Smarty::StreetLookup) do
  subject(:lookup) do
    described_class.new(addressee: 'Google', city: 'Mountain View', match:, secondary: 'Ste 4', state: 'CA',
                        street: '1600 Amphitheatre Pkwy', zipcode: '94043')
  end

  let(:match) { nil }
  let(:providers) { [Providers::Fake] }

  before do
    create(:country, iso3166_1_alpha2: 'US')
    allow(Providers).to(receive(:enabled).and_return(providers))
  end

  describe 'validations' do
    it { is_expected.to(validate_presence_of(:street)) }
  end

  describe '#candidates' do
    it { expect(lookup.candidates).to(contain_exactly(have_attributes(lookup:, valid?: true))) }

    context 'without a valid match' do
      let(:providers) { [] }

      it { expect(lookup.candidates).to(be_empty) }
    end

    context 'without a valid match in invalid mode' do
      let(:match) { 'invalid' }
      let(:providers) { [] }

      it { expect(lookup.candidates).to(contain_exactly(have_attributes(valid?: false))) }
    end
  end

  describe '#query' do
    it do
      expect(lookup.query).to(
        have_attributes(
          address_lines: ['1600 Amphitheatre Pkwy', 'Ste 4'],
          administrative_area: 'CA',
          locality: 'Mountain View',
          organization: 'Google',
          postal_code: '94043',
          region_code: 'US'
        )
      )
    end
  end

  describe '#strict?' do
    it { is_expected.to(be_strict) }
    it { expect(described_class.new(match: 'enhanced')).not_to(be_strict) }
    it { expect(described_class.new(match: 'invalid')).not_to(be_strict) }
  end
end
