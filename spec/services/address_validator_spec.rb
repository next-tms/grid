require 'rails_helper'

RSpec.describe(AddressValidator) do
  subject(:validator) { described_class.new(query, providers:) }

  let(:address) { create(:address, administrative_area:, country:, key: validator.normalized_query.key) }
  let(:administrative_area) { create(:administrative_area, country:) }
  let(:spelling) { AddressQuery.new(address_lines: ['1 main street'], locality: 'fremont', region_code: country.region_code) }
  let(:country) { create(:country, iso3166_1_alpha2: 'US') }
  let(:providers) { [Providers::Fake] }
  let(:query) { AddressQuery.new(address_lines: ['1 Main St'], locality: 'Fremont', region_code: country.region_code) }

  describe '#call' do
    let(:result) { validator.call }

    it { expect(result).to(be_a(AddressResult)) }
    it { expect { result }.to(change(Address, :count).by(1).and(change(Validation, :count).by(1))) }
    it { expect(result.validations.map(&:provider)).to(eq(['fake'])) }

    it { expect(result.address.provider_identifiers.pluck(:provider, :value)).to(eq([['fake', 'fake-1-main-st-fremont-us']])) }

    context 'with another spelling of the same address' do
      before { described_class.new(spelling, providers:).call }

      it { expect { result }.not_to(change(Address, :count)) }
      it { expect { result }.not_to(change(Validation, :count)) }
    end

    context 'when another address has the provider ID' do
      let(:other) { create(:address, administrative_area: create(:administrative_area, country:), country:) }

      before { create(:provider_identifier, identifiable: other, provider: 'fake', value: 'fake-1-main-st-fremont-us') }

      it { expect(result.address.provider_identifiers).to(be_empty) }
    end

    context 'when the provider is disabled after a verification' do
      before { described_class.new(query, providers:).call }

      it do
        expect(described_class.new(query, providers: []).call).to(
          have_attributes(authority: AuthorityRange.new(highest: :local, lowest: :local), validations: [])
        )
      end
    end

    context 'when the provider is enabled again' do
      before do
        described_class.new(query, providers:).call
        described_class.new(query, providers: []).call
      end

      it { expect { result }.not_to(change(Validation, :count)) }
      it { expect(result.authority.lowest).to(eq(:commercial)) }
    end

    context 'with an unexpired cached validation' do
      let!(:validation) { create(:validation, provider: 'fake', validatable: address) }

      it { expect { result }.not_to(change(Validation, :count)) }
      it { expect(result.validations).to(eq([validation])) }
    end

    context 'with an expired cached validation' do
      before { create(:validation, expires_at: 1.minute.ago, provider: 'fake', validatable: address) }

      it { expect { result }.to(change(Validation, :count).by(1)) }
    end

    context 'when the provider fails' do
      let(:adapter) { instance_double(Providers::Fake, supports?: true) }

      before do
        allow(adapter).to(receive(:call).and_raise(Providers::Error, 'down'))
        allow(Providers::Fake).to(receive(:new).and_return(adapter))
      end

      it { expect(result.validations).to(be_empty) }
    end

    context 'when the provider finds no match' do
      before { allow(Providers::Fake).to(receive(:new).and_return(instance_double(Providers::Fake, supports?: true, call: nil))) }

      it { expect(result.validations).to(be_empty) }
    end

    context 'when the provider does not support the query' do
      let(:query) { AddressQuery.new(locality: 'Fremont', region_code: country.region_code) }

      it { expect(result.validations).to(be_empty) }
    end

    context 'with a provider without a verification role' do
      let(:providers) do
        [
          Class.new(Providers::Base) do
            class << self
              def roles = %i[time_zone]
            end
          end
        ]
      end

      it { expect(validator.providers).to(be_empty) }
    end

    context 'when an earlier provider verifies and geocodes the address' do
      let(:providers) { [Providers::Fake, Providers::Smarty] }

      it { expect(result.validations.map(&:provider)).to(eq(['fake'])) }
    end

    context 'when an earlier provider verifies and geocodes without a dock' do
      let(:providers) { [Providers::Fake, Providers::OpenStreetMap] }
      let(:open_street_map) { build(:validation, dock: true, latitude: 37, longitude: -122, provider: 'open_street_map') }

      before do
        allow(Providers::OpenStreetMap).to(
          receive(:new).and_return(instance_double(Providers::OpenStreetMap, call: open_street_map, supports?: true))
        )
      end

      it { expect(result.validations.map(&:provider)).to(eq(['fake', 'open_street_map'])) }
      it { expect(result.dock).to(be(true)) }
    end

    context 'when an earlier provider verifies without a geocode' do
      let(:providers) { [Providers::Smarty, Providers::GeoNames] }
      let(:query) { AddressQuery.new(postal_code: '97701', region_code: country.region_code) }
      let(:smarty) { build(:validation, locality: 'Bend', provider: 'smarty', validation_granularity: 'OTHER') }
      let(:geo_names) { build(:validation, latitude: 44, longitude: -121, provider: 'geo_names', validation_granularity: 'OTHER') }

      before do
        allow(Providers::Smarty).to(receive(:new).and_return(instance_double(Providers::Smarty, call: smarty, supports?: true)))
        allow(Providers::GeoNames).to(receive(:new).and_return(instance_double(Providers::GeoNames, call: geo_names, supports?: true)))
      end

      it { expect(result.validations).to(eq([smarty, geo_names])) }
      it { expect(result).to(have_attributes(locality: 'Bend', validation: smarty, geocode: geo_names)) }
    end

    context 'when an earlier provider geocodes without a verification' do
      let(:providers) { [Providers::OpenStreetMap, Providers::Google] }
      let(:open_street_map) { build(:validation, latitude: 37, longitude: -122, provider: 'open_street_map') }

      before do
        allow(Providers::OpenStreetMap).to(
          receive(:new).and_return(instance_double(Providers::OpenStreetMap, call: open_street_map, supports?: true))
        )
        allow(Providers::Google).to(receive(:new).and_call_original)
      end

      it { expect(result.validations).to(eq([open_street_map])) }

      it do
        result

        expect(Providers::Google).not_to(have_received(:new))
      end
    end

    context 'with an unknown region code' do
      let(:query) { AddressQuery.new(address_lines: ['1 Main St'], region_code: 'ZZ') }

      it { expect { result }.to(raise_error(ActiveRecord::RecordNotFound)) }
    end
  end
end
