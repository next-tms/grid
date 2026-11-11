require 'rails_helper'

RSpec.describe(AddressQuery) do
  subject(:query) do
    described_class.new(
      address_lines: [' 1600  Amphitheatre Pkwy ', '', nil],
      administrative_area: 'CA',
      locality: 'Mountain View',
      postal_code: '94043',
      region_code: ' us '
    )
  end

  describe '#address_lines' do
    it { expect(query.address_lines).to(eq(['1600 Amphitheatre Pkwy'])) }
    it { expect(described_class.new.address_lines).to(eq([])) }
    it { expect(described_class.new(address_lines: '1 Main St').address_lines).to(eq(['1 Main St'])) }
  end

  describe '#region_code' do
    it { expect(query.region_code).to(eq('US')) }
    it { expect(described_class.new(region_code: ' ').region_code).to(be_nil) }
  end

  describe '#street?' do
    it { is_expected.to(be_street) }
    it { expect(described_class.new(postal_code: '94043')).not_to(be_street) }
  end

  describe '#to_s' do
    it { expect(query.to_s).to(eq('1600 Amphitheatre Pkwy, Mountain View, CA 94043, US')) }
  end
end
