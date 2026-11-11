require 'rails_helper'

RSpec.describe(TimeZoneSearch) do
  subject(:search) { described_class.new(name:, region_code:) }

  let(:name) { nil }
  let(:region_code) { nil }

  describe '#call' do
    it { expect(search.call.map(&:name)).to(include('America/Los_Angeles', 'Europe/London')) }
    it { expect(search.call).to(all(have_attributes(authority: nil, expires_at: nil))) }

    context 'with part of an IANA name' do
      let(:name) { ' los angeles ' }

      it { expect(search.call.map(&:name)).to(eq(['America/Los_Angeles'])) }
    end

    context 'with an Active Support name' do
      let(:name) { 'Pacific Time (US & Canada)' }

      it { expect(search.call.map(&:name)).to(eq(['America/Los_Angeles'])) }
    end

    context 'with a tzdata abbreviation' do
      let(:name) { 'pst' }

      it { expect(search.call.map(&:name)).to(include('America/Los_Angeles')) }
    end

    context 'with a region code' do
      let(:region_code) { 'us' }

      it { expect(search.call.map(&:name)).to(include('America/Chicago', 'Pacific/Honolulu')) }
      it { expect(search.call.map(&:name)).not_to(include('Europe/London')) }
    end

    context 'with an unknown region code' do
      let(:region_code) { 'ZZ' }

      it { expect(search.call).to(be_empty) }
    end
  end
end
