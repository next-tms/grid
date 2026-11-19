require 'rails_helper'

RSpec.describe(PlaceId) do
  describe '.for' do
    it { expect(described_class.for('overture', 'overture-1')).to(eq('ff13f208-9944-50f5-b56b-1cbc9616659c')) }
    it { expect(described_class.for('overture', 'overture-1')).not_to(eq(described_class.for('google', 'overture-1'))) }
    it { expect(described_class.for('overture', 'overture-1')).to(match(/\A\h{8}-\h{4}-5\h{3}-[89ab]\h{3}-\h{12}\z/)) }
  end
end
