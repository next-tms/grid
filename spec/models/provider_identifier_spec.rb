require 'rails_helper'

RSpec.describe(ProviderIdentifier) do
  subject { build(:provider_identifier) }

  describe 'relationships' do
    it { is_expected.to(belong_to(:identifiable)) }
  end

  describe 'validations' do
    it { is_expected.to(be_valid) }
    it { is_expected.to(validate_presence_of(:provider)) }
    it { is_expected.to(validate_presence_of(:value)) }
    it { is_expected.to(validate_uniqueness_of(:provider).scoped_to(:identifiable_type, :identifiable_id)) }
    it { is_expected.to(validate_uniqueness_of(:value).scoped_to(:identifiable_type, :provider)) }
  end
end
