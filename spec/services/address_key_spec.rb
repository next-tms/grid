require 'rails_helper'

RSpec.describe(AddressKey) do
  describe '.for' do
    let(:query) { AddressQuery.new(address_lines: ['1600 Amphitheatre Parkway.'], postal_code: '94043-1351', region_code: 'US') }

    it { expect(described_class.for(query)).to(eq('1600 AMPHITHEATRE PKWY, 94043, US')) }
    it { expect(described_class.for(AddressQuery.new(address_lines: ['1 Main St'], region_code: 'US'))).to(be_nil) }

    context 'with a unit' do
      let(:query) { AddressQuery.new(address_lines: ['935 Sierra Vista Ave  Ste C'], postal_code: '94043-1759', region_code: 'US') }

      it { expect(described_class.for(query)).to(eq('935 SIERRA VISTA AVE, 94043, US')) }
    end

    it { expect(described_class.for(AddressQuery.new(postal_code: '94043', region_code: 'US'))).to(be_nil) }
  end
end
