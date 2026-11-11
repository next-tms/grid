require 'rails_helper'

RSpec.describe(JSONKeys) do
  describe '.parse' do
    it { expect(described_class.parse('[{"cityStates":[{"defaultCity":true}]}]')).to(eq([{ city_states: [{ default_city: true }] }])) }
    it { expect(described_class.parse('{"dpvCMRA":"N"}')).to(eq({ dpv_cmra: 'N' })) }
    it { expect(described_class.parse('"OK"')).to(eq('OK')) }
  end

  describe 'LOWER_CAMEL_CASE' do
    it { expect(described_class::LOWER_CAMEL_CASE.call('city_state_zip_address_line')).to(eq('cityStateZipAddressLine')) }
    it { expect(described_class::LOWER_CAMEL_CASE.call('delivery_line_1')).to(eq('deliveryLine1')) }
    it { expect(described_class::LOWER_CAMEL_CASE.call('status')).to(eq('status')) }
  end
end
