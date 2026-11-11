require 'rails_helper'

RSpec.describe(Overture::Schema) do
  describe '.version' do
    it { expect(described_class.version).to(match(/\A\h{12}\z/)) }

    context 'when a schema file changes' do
      let!(:version) { described_class.version }

      before do
        allow(Rails.root).to(receive(:join).and_call_original)
        allow(Rails.root).to(receive(:join).with('config/usps_publication_28.yml').and_return(StringIO.new('changed')))
      end

      it { expect(described_class.version).not_to(eq(version)) }
    end
  end
end
