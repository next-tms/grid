require 'rails_helper'

RSpec.describe(Fingerprint) do
  describe '.of' do
    subject(:fingerprint) { described_class.of(sources) }

    let(:sources) { [create(:validation)] }

    it { is_expected.to(match(/\A\h{32}\z/)) }
    it { is_expected.to(eq(described_class.of(sources.map { Validation.find(it.id) }))) }

    it do
      response = ActionDispatch::Response.new
      response.weak_etag = [sources]

      expect(response.etag).to(eq(%(W/"#{fingerprint}")))
    end

    context 'with a changed source' do
      it { is_expected.not_to(eq(described_class.of(sources.each { it.update!(updated_at: 1.minute.from_now) }))) }
    end
  end
end
