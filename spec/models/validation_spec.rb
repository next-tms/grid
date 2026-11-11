require 'rails_helper'

RSpec.describe(Validation) do
  subject(:validation) { build(:validation) }

  describe 'normalizations' do
    it { is_expected.to(normalize(:address_lines).from(['  1600  Amphitheatre Pkwy ', '', nil]).to(['1600 Amphitheatre Pkwy'])) }
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:validatable)) }
    it { is_expected.to(have_many(:places).dependent(:destroy)) }
  end

  describe 'scopes' do
    describe '.unexpired' do
      let!(:expired) { create(:validation, expires_at: 1.minute.ago) }
      let!(:unexpired) { create(:validation) }

      it { expect(described_class.unexpired).to(contain_exactly(unexpired)) }
      it { expect(described_class.unexpired).not_to(include(expired)) }
    end
  end

  describe 'validations' do
    it { is_expected.to(be_valid) }
    it { is_expected.to(validate_inclusion_of(:geocode_granularity).in_array(described_class::GEOCODE_GRANULARITIES).allow_nil) }
    it { is_expected.to(validate_inclusion_of(:validation_granularity).in_array(described_class::VALIDATION_GRANULARITIES).allow_nil) }
    it { is_expected.to(validate_numericality_of(:latitude).is_in(-90..90).allow_nil) }
    it { is_expected.to(validate_numericality_of(:longitude).is_in(-180..180).allow_nil) }
    it { is_expected.to(validate_presence_of(:expires_at)) }
    it { is_expected.to(validate_presence_of(:fetched_at)) }
    it { is_expected.to(validate_presence_of(:provider)) }
    it { is_expected.to(allow_value('US', nil).for(:region_code)) }
    it { is_expected.not_to(allow_value('USA', 'us').for(:region_code)) }
  end

  describe '#expired?' do
    it { expect(build(:validation, expires_at: 1.minute.ago)).to(be_expired) }
    it { expect(build(:validation)).not_to(be_expired) }
  end

  describe '#stores_content?' do
    it { is_expected.to(be_stores_content) }
    it { expect(build(:validation, provider: 'google')).not_to(be_stores_content) }
    it { expect(build(:validation, provider: 'retired')).to(be_stores_content) }
  end
end
