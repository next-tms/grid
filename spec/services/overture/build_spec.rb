require 'rails_helper'

RSpec.describe(Overture::Build) do
  subject(:overture_build) { described_class.new(path:, region_code: 'US', release: '2026-10-22.0', source: "/data/it's/*.parquet") }

  self.use_transactional_tests = false

  let(:csv) do
    <<~CSV
      id,name,basic_category,primary_category,operating_status,freeform,locality,region,postcode,country,latitude,longitude
      place-1,Open Cafe,coffee_shop,cafe,open,1600 Amphitheatre Parkway,Mountain View,US-CA,94043,US,37.42241,-122.08561
      place-2,No Street,coffee_shop,,open,,Mountain View,CA,94043,US,,
      place-3,,coffee_shop,,open,1 Main St,Mountain View,CA,94043,US,,
      place-4,Broken Street,coffee_shop,,,"4\u00004\u00004\u0000 \u0000A\u0000l\u0000a\u0000s\u0000k\u0000a\u0000 \u0000A\u0000v\u0000e",Torrance,CA,90503,US,,
    CSV
  end
  let(:path) { Rails.root.join('tmp/overture_build_test.sqlite3') }
  let(:places) { SQLite3::Database.new(path.to_s, results_as_hash: true).execute('SELECT * FROM places') }
  let(:status) { instance_double(Process::Status, exitstatus: 0, success?: true) }

  before do
    allow(IO).to(receive(:popen).and_yield(StringIO.new(csv)))
    allow(Process).to(receive(:last_status).and_return(status))
  end

  after { FileUtils.rm_f(path) }

  describe '.source' do
    let(:source) { 's3://overturemaps-us-west-2/release/2026-10-22.0/theme=places/type=place/*' }

    it { expect(described_class.source('2026-10-22.0')).to(eq(source)) }
  end

  describe '#call' do
    it { expect(overture_build.call).to(eq(2)) }

    it do
      overture_build.call

      releases = SQLite3::Database.new(path.to_s, results_as_hash: true).execute('SELECT * FROM releases')
      expect(releases).to(eq([{ 'name' => '2026-10-22.0', 'schema_version' => Overture::Schema.version }]))
    end

    it do
      overture_build.call

      expect(places).to(
        contain_exactly(
          include('address_key' => '444 ALASKA AVE, 90503, US', 'freeform' => '444 Alaska Ave', 'operating_status' => nil),
          include(
            'address_key' => '1600 AMPHITHEATRE PKWY, 94043, US',
            'basic_category' => 'coffee_shop',
            'freeform' => '1600 Amphitheatre Parkway',
            'id' => 'place-1',
            'latitude' => 37.42241,
            'name' => 'Open Cafe',
            'operating_status' => 'open',
            'primary_category' => 'cafe',
            'region' => 'US-CA'
          )
        )
      )
    end

    it do
      overture_build.call

      expect(IO).to(have_received(:popen).with(['duckdb', '-csv', '-nullvalue', '', '-c', include("read_parquet('/data/it''s/*.parquet'")]))
    end

    it do
      overture_build.call

      expect(Overture::Place.connection_db_config.database).to(end_with('tmp/overture_test.sqlite3'))
    end

    context 'when duckdb fails' do
      let(:status) { instance_double(Process::Status, exitstatus: 1, success?: false) }

      it { expect { overture_build.call }.to(raise_error(Providers::Error, 'duckdb exited with 1')) }

      it do
        overture_build.call
      rescue Providers::Error
        expect(File).not_to(exist(path))
      end
    end

    context 'with an invalid region code' do
      it { expect { described_class.new(path:, region_code: "US'", source: '') }.to(raise_error(ArgumentError)) }
    end
  end
end
