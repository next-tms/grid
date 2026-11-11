require 'rails_helper'

RSpec.describe(GeoNames::Schema) do
  describe '.postal_codes_for' do
    it { expect(described_class.postal_codes_for('US', '97701-1234')).to(eq(['97701-1234', '97701'])) }
    it { expect(described_class.postal_codes_for('CA', 't2p1j9')).to(eq(['T2P 1J9', 'T2P'])) }
    it { expect(described_class.postal_codes_for('GB', 'SW1A 2AA')).to(eq(['SW1A 2AA', 'SW1A'])) }
    it { expect(described_class.postal_codes_for('NL', '1012AB')).to(eq(['1012 AB', '1012'])) }
    it { expect(described_class.postal_codes_for('CA', 'T2P')).to(eq(['T2P'])) }
    it { expect(described_class.postal_codes_for('US', ' ')).to(eq([])) }
  end

  describe '.version' do
    it { expect(described_class.version).to(match(/\A\h{12}\z/)) }
  end
end
