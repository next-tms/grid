require 'rails_helper'

RSpec.describe(Address) do
  subject(:address) { build(:address) }

  describe '.from_place_id!' do
    let(:address) { create(:address) }

    context 'with a Grid place ID' do
      it { expect(described_class.from_place_id!(address.place_id)).to(eq(address)) }
    end

    context 'with a stored Google place ID' do
      before { create(:provider_identifier, identifiable: address, provider: 'google', value: 'ChIJ') }

      it { expect(described_class.from_place_id!('ChIJ')).to(eq(address)) }
    end

    context 'with an unknown Grid place ID' do
      it { expect { described_class.from_place_id!('grid:0193a8f2-7c4e-7b1a-9f3d-2e5c8b6a4d10') }.to(raise_error(ActiveRecord::RecordNotFound)) }
    end

    context 'with an empty Grid place ID' do
      it { expect { described_class.from_place_id!('grid:') }.to(raise_error(ActiveRecord::RecordNotFound)) }
    end
  end

  describe '#place_id' do
    it { expect(build(:address, id: '0193a8f2-7c4e-7b1a-9f3d-2e5c8b6a4d10').place_id).to(eq('grid:0193a8f2-7c4e-7b1a-9f3d-2e5c8b6a4d10')) }
  end

  describe 'normalizations' do
    it { is_expected.to(normalize(:address_lines).from(['  1600  Amphitheatre Pkwy ', '', nil]).to(['1600 Amphitheatre Pkwy'])) }
  end

  describe 'id' do
    it { expect(create(:address).id).to(match(/\A\h{8}-\h{4}-7\h{3}-\h{4}-\h{12}\z/)) }
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:administrative_area).optional) }
    it { is_expected.to(belong_to(:country)) }
    it { is_expected.to(belong_to(:locality).optional) }
    it { is_expected.to(belong_to(:postal_code).optional) }
    it { is_expected.to(have_many(:places).dependent(:destroy)) }
    it { is_expected.to(have_many(:provider_identifiers).dependent(:destroy)) }
    it { is_expected.to(have_many(:validations).dependent(:destroy)) }
  end

  describe 'validations' do
    it { is_expected.to(be_valid) }
    it { is_expected.to(validate_presence_of(:key)) }
    it { is_expected.to(validate_uniqueness_of(:key)) }

    context 'when the administrative area is in another country' do
      before { address.administrative_area = create(:administrative_area) }

      it { is_expected.not_to(be_valid) }
    end

    context 'when the locality is in another administrative area' do
      before { address.locality = create(:locality) }

      it { is_expected.not_to(be_valid) }
    end

    context 'when the postal code is in another country' do
      before { address.postal_code = create(:postal_code) }

      it { is_expected.not_to(be_valid) }
    end

    context 'without an administrative area, locality, or postal code' do
      subject(:address) { build(:address, administrative_area: nil, locality: nil, postal_code: nil, country: create(:country)) }

      it { is_expected.to(be_valid) }
    end
  end

  describe '#query' do
    let(:address) { create(:address, organization: 'Google') }

    it do
      expect(address.query).to(
        have_attributes(
          address_lines: ['1600 Amphitheatre Pkwy'],
          administrative_area: address.administrative_area.abbreviation,
          locality: address.locality.name,
          organization: 'Google',
          postal_code: address.postal_code.value,
          region_code: address.country.region_code
        )
      )
    end

    context 'with an unexpired validation' do
      let(:attributes) { { address_lines: ['1600 Amphitheatre Parkway'], locality: 'Mountain View', postal_code: '94043' } }

      before do
        allow(Providers).to(receive(:enabled).and_return(providers))
        create(:validation, **attributes, validatable: address, validation_granularity: 'PREMISE')
      end

      context 'when its provider is enabled' do
        let(:providers) { [Providers::Smarty] }

        it { expect(address.query).to(have_attributes(attributes)) }
      end

      context 'when its provider is disabled' do
        let(:providers) { [] }

        it { expect(address.query).to(have_attributes(address_lines: ['1600 Amphitheatre Pkwy'], locality: address.locality.name)) }
      end
    end
  end

  describe '#residential?' do
    let(:address) { create(:address) }

    before { allow(Providers).to(receive(:enabled).and_return([Providers::Smarty])) }

    it { is_expected.not_to(be_residential) }

    context 'with a residential validation' do
      before { create(:validation, residential: true, validatable: address) }

      it { expect(address).to(be_residential) }
    end

    context 'with a residential validation from a disabled provider' do
      before { create(:validation, provider: 'geo_names', residential: true, validatable: address) }

      it { expect(address).not_to(be_residential) }
    end
  end

  describe '#validation_for' do
    let(:address) { create(:address) }
    let(:query) { AddressQuery.new(address_lines: ['1 Main St'], region_code: 'US') }

    it { expect(address.validation_for(Providers::Fake, query)).to(be_persisted) }
    it { expect(address.validation_for(Providers::Fake, query)).to(have_attributes(provider: 'fake', validatable: address)) }
    it { expect(address.validation_for(Providers::Fake, AddressQuery.new)).to(be_nil) }

    it { expect(address.validation_for(Providers::Fake, query).places.map(&:name)).to(contain_exactly('Fake Cafe', 'Fake Office')) }

    context 'with an unexpired validation' do
      let!(:validation) { create(:validation, provider: 'fake', validatable: address) }

      it { expect(address.validation_for(Providers::Fake, query)).to(eq(validation)) }
    end

    context 'with an expired validation that has places' do
      let!(:place) { address.validation_for(Providers::Fake, query).places.find_by!(name: 'Fake Cafe') }

      before { travel(2.minutes) }

      it { expect(address.validation_for(Providers::Fake, query).places).to(include(place)) }
      it { expect { address.validation_for(Providers::Fake, query) }.not_to(change(Place, :count)) }
    end

    context 'with a provider that must not store content' do
      let(:body) { Rails.root.join('spec/fixtures/google/text_search.json').read }
      let(:google) { address.validation_for(Providers::Google, query) }
      let(:query) { AddressQuery.new(address_lines: ['1600 Amphitheatre Pkwy'], region_code: 'US') }

      before do
        allow(ENV).to(receive(:fetch).and_call_original)
        allow(ENV).to(receive(:fetch).with('GOOGLE_API_KEY').and_return('key'))
        stub_request(:post, Providers::Google::SEARCH_ENDPOINT.to_s).to_return(body:)
      end

      it { expect(google).to(have_attributes(permanently_closed: nil, types: ['premise', 'street_address'])) }
      it { expect(google.places.sort_by(&:name).map(&:name)).to(eq(['Closed Cafe', 'Googleplex'])) }
      it { expect(google.reload).to(have_attributes(raw: {}, types: [])) }
      it { expect(google.places.map { it.reload.name }).to(all(be_nil)) }
      it { expect(google.places.flat_map { it.reload.types }).to(be_empty) }

      it do
        google

        expect(address.provider_identifiers.find_by!(provider: 'google').value).to(eq('ChIJtest-address-1600'))
      end

      it do
        google

        expect { address.validation_for(Providers::Google, query) }.not_to(change { [Place.count, Validation.count] })
      end

      it do
        place = google.places.find { it.name == 'Googleplex' }

        expect(address.validation_for(Providers::Google, query).places.map(&:id)).to(include(place.id))
      end
    end

    context 'when the provider fails' do
      let(:adapter) { instance_double(Providers::Fake, supports?: true) }

      before do
        allow(adapter).to(receive(:call).and_raise(Providers::Error))
        allow(Providers::Fake).to(receive(:new).and_return(adapter))
        allow(Sentry).to(receive(:capture_exception))
      end

      it { expect(address.validation_for(Providers::Fake, query)).to(be_nil) }

      it do
        address.validation_for(Providers::Fake, query)

        expect(Sentry).to(have_received(:capture_exception).with(instance_of(Providers::Error)))
      end
    end
  end
end
