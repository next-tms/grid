require 'rails_helper'

RSpec.describe(CountrySearch) do
  subject(:search) { described_class.new(name:) }

  let(:name) { nil }

  describe '#call' do
    it { expect(search.call.map(&:alpha2)).to(include('CA', 'MX', 'US')) }
    it { expect(search.call.size).to(eq(ISO3166::Country.all.size)) }

    context 'with an alpha-2 code' do
      let(:name) { 'us' }

      it { expect(search.call.map(&:alpha2)).to(eq(['US'])) }
    end

    context 'with an alpha-3 code' do
      let(:name) { 'can' }

      it { expect(search.call.map(&:alpha2)).to(eq(['CA'])) }
    end

    context 'with an unofficial name' do
      let(:name) { ' United States of America ' }

      it { expect(search.call.map(&:alpha2)).to(eq(['US'])) }
    end

    context 'with an unknown name' do
      let(:name) { 'Atlantis' }

      it { expect(search.call).to(be_empty) }
    end

    context 'with a blank name' do
      let(:name) { ' ' }

      it { expect(search.call.size).to(eq(ISO3166::Country.all.size)) }
    end
  end
end
