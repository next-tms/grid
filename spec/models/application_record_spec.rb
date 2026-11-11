require 'rails_helper'

RSpec.describe(ApplicationRecord) do
  describe '#id' do
    it { expect(create(:country).id).to(match(/\A\h{8}-\h{4}-7\h{3}-[89ab]\h{3}-\h{12}\z/)) }

    context 'with an id' do
      let(:id) { SecureRandom.uuid }

      it { expect(create(:country, id:).id).to(eq(id)) }
    end
  end
end
