require 'rails_helper'

RSpec.describe(TimeZoneLookup) do
  subject(:lookup) { described_class.new(location, providers:) }

  let(:location) { Location.new(latitude: 37.42241, longitude: -122.08561) }
  let(:providers) { [Providers::Google, Providers::Fake] }

  describe '#call' do
    it { expect(lookup.call).to(have_attributes(name: 'America/Los_Angeles')) }
    it { expect(lookup.providers).to(eq([Providers::Fake])) }

    context 'without time zone providers' do
      let(:providers) { [] }

      it { expect(lookup.call).to(be_nil) }
    end

    context 'when the provider fails' do
      let(:adapter) { instance_double(Providers::Fake, supports?: true) }

      before do
        allow(adapter).to(receive(:time_zone_name).and_raise(Providers::Error, 'down'))
        allow(Providers::Fake).to(receive(:new).and_return(adapter))
      end

      it { expect { lookup.call }.to(raise_error(Providers::Error, 'down')) }
    end
  end
end
