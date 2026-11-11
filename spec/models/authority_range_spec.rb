require 'rails_helper'

RSpec.describe(AuthorityRange) do
  describe '.of' do
    it { expect(described_class.of([:open_data, :certified, nil])).to(eq(described_class.new(highest: :certified, lowest: :open_data))) }
    it { expect(described_class.of([])).to(be_nil) }
  end

  describe '.quality' do
    it { expect(Providers::Base::AUTHORITIES.map { described_class.quality(it) }).to(eq([1.0, 0.8, 0.6, 0.4, 0.2, 0.0])) }
  end

  describe '#quality' do
    it { expect(described_class.new(highest: :certified, lowest: :local).quality).to(eq(0.3)) }
    it { expect(described_class.new(highest: :postal_operator, lowest: :postal_operator).quality).to(eq(1.0)) }
    it { expect(described_class.new(highest: :government, lowest: :open_data).quality).to(eq(0.6)) }
  end
end
