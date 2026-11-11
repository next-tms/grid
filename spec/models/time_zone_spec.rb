require 'rails_helper'

RSpec.describe(TimeZone) do
  describe '.find' do
    it { expect(described_class.find('America/Chicago')).to(have_attributes(authority: nil, expires_at: nil, name: 'America/Chicago')) }
    it { expect(described_class.find('Mars/Olympus_Mons')).to(be_nil) }
  end

  describe '#authority' do
    it { expect(described_class.new(expires_at: nil, fetched_at: nil, name: 'UTC', provider: 'geo_names').authority).to(eq(:open_data)) }
  end
end
