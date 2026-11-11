require 'rails_helper'

RSpec.describe(Smarty::Candidate) do
  subject(:candidate) { described_class.new(lookup:, result:) }

  let(:lookup) { Smarty::StreetLookup.new(input_id: 'abc', street: '1600 Amphitheatre Pkwy') }
  let(:result) { AddressResult.new(address: build(:address), query: lookup.query, validations:) }
  let(:validation) do
    build(
      :validation,
      address_lines: ['1600 Amphitheatre Pkwy', 'Ste 4'],
      administrative_area: 'CA',
      business: false,
      dpv_confirmation: 'Y',
      geocode_granularity: 'ROUTE',
      latitude: 1,
      locality: 'Mountain View',
      longitude: 2,
      po_box: true,
      postal_code: '94043-1351',
      residential: true,
      validation_granularity: 'PREMISE'
    )
  end
  let(:validations) { [validation] }

  it do
    expect(candidate).to(
      have_attributes(
        delivery_line_1: '1600 Amphitheatre Pkwy',
        delivery_line_2: 'Ste 4',
        input_id: 'abc',
        last_line: 'Mountain View CA 94043-1351',
        plus4_code: '1351',
        precision: 'Street',
        rdi: 'Residential',
        record_type: 'P',
        valid?: true,
        zipcode: '94043'
      )
    )
  end

  context 'with a business' do
    before { validation.business = true }

    it { expect(candidate.rdi).to(eq('Commercial')) }
  end

  context 'with an unconfirmed address' do
    before { validation.dpv_confirmation = 'N' }

    it { is_expected.not_to(be_valid) }
  end

  context 'without validations' do
    let(:validations) { [] }

    it { expect(candidate).to(have_attributes(plus4_code: nil, precision: 'Unknown', rdi: nil, record_type: nil, valid?: false)) }
  end
end
