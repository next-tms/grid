require 'rails_helper'

RSpec.describe(AddressNormalizer) do
  subject(:normalized) { described_class.new(query).call }

  let(:query) { AddressQuery.new(address_lines:, region_code:, **attributes) }
  let(:address_lines) { [] }
  let(:attributes) { {} }
  let(:region_code) { 'US' }

  describe '.tables' do
    it { expect(described_class.tables.keys).to(eq(['directionals', 'secondary_unit_designators', 'states', 'street_suffixes'])) }
  end

  describe '#call' do
    context 'with a street suffix' do
      let(:address_lines) { ['1600 Amphitheatre Parkway'] }

      it { expect(normalized.address_lines).to(eq(['1600 AMPHITHEATRE PKWY'])) }
    end

    context 'with punctuation' do
      let(:address_lines) { ['100 N. Main St., Suite #200'] }

      it { expect(normalized.address_lines).to(eq(['100 N MAIN ST STE 200'])) }
    end

    context 'with an apostrophe' do
      let(:address_lines) { ['123 O’Farrell St Apt 4B'] }

      it { expect(normalized.address_lines).to(eq(['123 OFARRELL ST APT 4B'])) }
    end

    context 'with a predirectional' do
      let(:address_lines) { ['100 North Main Street'] }

      it { expect(normalized.address_lines).to(eq(['100 N MAIN ST'])) }
    end

    context 'with a postdirectional' do
      let(:address_lines) { ['100 Main Street North'] }

      it { expect(normalized.address_lines).to(eq(['100 MAIN ST N'])) }
    end

    context 'with a directional as the street name' do
      let(:address_lines) { ['100 North Street'] }

      it { expect(normalized.address_lines).to(eq(['100 NORTH ST'])) }
    end

    context 'with a suffix as the street name' do
      let(:address_lines) { ['12 Court Street'] }

      it { expect(normalized.address_lines).to(eq(['12 COURT ST'])) }
    end

    context 'with a pound sign unit' do
      let(:address_lines) { ['100 Main St #200'] }

      it { expect(normalized.address_lines).to(eq(['100 MAIN ST # 200'])) }
    end

    context 'with a unit after a street without a suffix' do
      let(:address_lines) { ['1 Avenue of the Americas Floor 5'] }

      it { expect(normalized.address_lines).to(eq(['1 AVENUE OF THE AMERICAS FL 5'])) }
    end

    context 'with a unit designator as the street name' do
      let(:address_lines) { ['100 Front 5th St'] }

      it { expect(normalized.address_lines).to(eq(['100 FRONT 5TH ST'])) }
    end

    context 'with a PO box' do
      let(:address_lines) { ['P.O. Box 123', 'Post Office Box 9'] }

      it { expect(normalized.address_lines).to(eq(['PO BOX 123', 'PO BOX 9'])) }
    end

    context 'with a state name' do
      let(:attributes) { { administrative_area: 'California' } }

      it { expect(normalized.administrative_area).to(eq('CA')) }
    end

    context 'with a state code' do
      let(:attributes) { { administrative_area: 'ca' } }

      it { expect(normalized.administrative_area).to(eq('CA')) }
    end

    context 'with a nine-digit ZIP code' do
      let(:attributes) { { postal_code: '940431351' } }

      it { expect(normalized.postal_code).to(eq('94043-1351')) }
    end

    context 'with a malformed ZIP code' do
      let(:attributes) { { postal_code: '9404' } }

      it { expect(normalized.postal_code).to(eq('9404')) }
    end

    context 'with two spellings of one address' do
      let(:other) do
        AddressQuery.new(address_lines: ['1600 amphitheatre pkwy.'], locality: 'mountain view', postal_code: '94043', region_code: 'US')
      end
      let(:address_lines) { ['1600 Amphitheatre Parkway'] }
      let(:attributes) { { locality: 'Mountain View', postal_code: '94043' } }

      it { expect(normalized.key).to(eq(described_class.new(other).call.key)) }
    end

    context 'with a region outside the US' do
      let(:address_lines) { ['10 Downing Street.'] }
      let(:attributes) { { administrative_area: 'England', postal_code: 'sw1a 2aa' } }
      let(:region_code) { 'GB' }

      let(:expected) { { address_lines: ['10 DOWNING STREET'], administrative_area: 'ENGLAND', postal_code: 'SW1A 2AA' } }

      it { expect(normalized).to(have_attributes(expected)) }
    end

    context 'with blank fields' do
      let(:attributes) { { locality: ' ', organization: nil } }

      it { expect(normalized).to(have_attributes(address_lines: [], locality: nil, organization: nil)) }
    end
  end

  describe '#street_line' do
    subject(:street_line) { normalizer.street_line }

    let(:normalizer) { described_class.new(query) }

    context 'with a unit' do
      let(:address_lines) { ['935 Sierra Vista Avenue, Suite C'] }

      it { is_expected.to(eq('935 SIERRA VISTA AVE')) }
    end

    context 'with a number sign' do
      let(:address_lines) { ['935 Sierra Vista Ave #C'] }

      it { is_expected.to(eq('935 SIERRA VISTA AVE')) }
    end

    context 'with a PO box' do
      let(:address_lines) { ['P.O. Box 12'] }

      it { is_expected.to(eq('PO BOX 12')) }
    end

    context 'with a region outside the US' do
      let(:address_lines) { ['10 Downing Street, Flat 2'] }
      let(:region_code) { 'GB' }

      it { is_expected.to(eq('10 DOWNING STREET FLAT 2')) }
    end

    context 'without address lines' do
      let(:address_lines) { [] }

      it { is_expected.to(be_nil) }
    end
  end
end
