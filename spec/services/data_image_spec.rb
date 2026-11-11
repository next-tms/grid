require 'rails_helper'

RSpec.describe(DataImage) do
  subject(:data_image) { described_class.new(previous_image: 'ghcr.io/next-tms/grid-data:latest', previous_labels:, releases:) }

  let!(:previous_labels) do
    {
      'com.next-tms.grid-data.geo_names.release' => '2026-10',
      'com.next-tms.grid-data.geo_names.schema-version' => GeoNames::Schema.version,
      'com.next-tms.grid-data.overture.release' => '2026-10-21.0',
      'com.next-tms.grid-data.overture.schema-version' => Overture::Schema.version
    }
  end
  let(:releases) { { 'geo_names' => '2026-11', 'overture' => '2026-10-21.0' } }

  describe '.version' do
    it { expect(described_class.version).to(match(/\A\h{12}\z/)) }
  end

  describe '#builds' do
    it { expect(data_image.builds).to(eq(['geo_names'])) }

    context 'with a new Overture schema version' do
      before { allow(Overture::Schema).to(receive(:version).and_return('000000000000')) }

      it { expect(data_image.builds).to(eq(['geo_names', 'overture'])) }
    end

    context 'without a previous image' do
      let(:previous_labels) { {} }

      it { expect(data_image.builds).to(eq(['geo_names', 'overture'])) }
    end
  end

  describe '#dockerfile' do
    it { expect(data_image.dockerfile).to(include("FROM ghcr.io/next-tms/grid-data:latest AS previous\nFROM scratch\n")) }
    it { expect(data_image.dockerfile).to(include('COPY --link geo_names.sqlite3 /data/geo_names.sqlite3')) }
    it { expect(data_image.dockerfile).to(include('COPY --link --from=previous /data/overture.sqlite3 /data/overture.sqlite3')) }
    it { expect(data_image.dockerfile).to(include('LABEL com.next-tms.grid-data.geo_names.release="2026-11"')) }

    context 'without a previous image' do
      let(:previous_labels) { {} }

      it { expect(data_image.dockerfile).not_to(include('AS previous')) }
    end
  end
end
