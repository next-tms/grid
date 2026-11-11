require 'rails_helper'

RSpec.describe(Location) do
  describe '.parse' do
    it { expect(described_class.parse('37.42241,-122.08561')).to(eq(described_class.new(latitude: 37.42241, longitude: -122.08561))) }
    it { expect(described_class.parse(' 37.4 , -122.0 ')).to(eq(described_class.new(latitude: 37.4, longitude: -122.0))) }
    it { expect(described_class.parse('91,0')).to(be_nil) }
    it { expect(described_class.parse('0,181')).to(be_nil) }
    it { expect(described_class.parse('abc,def')).to(be_nil) }
    it { expect(described_class.parse('37.4')).to(be_nil) }
    it { expect(described_class.parse(nil)).to(be_nil) }
  end

  describe '#plus_code' do
    it { expect(described_class.new(latitude: 37.42241, longitude: -122.08561).plus_code).to(eq('849VCWC7+XQ')) }
    it { expect(described_class.new(latitude: 20.3700625, longitude: 2.7821875).plus_code).to(eq('7FG49QCJ+2V')) }
    it { expect(described_class.new(latitude: 90, longitude: 180).plus_code).to(eq('C2X2X2X2+X2')) }
  end

  describe '#cache_key' do
    it { expect(described_class.new(latitude: 37.422412, longitude: -122.085614).cache_key).to(eq('37.4224,-122.0856')) }
  end
end
