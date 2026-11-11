require 'rails_helper'

RSpec.describe(GeoNames::Build) do
  subject(:geo_names_build) { described_class.new(path:, release: '2026-11', source: '/data/geo_names') }

  self.use_transactional_tests = false

  let(:lines) do
    {
      'dump/cities500.zip' => "5713587\tBend\tBend\t\t44.05817\t-121.31531\tP\tPPLA2\tUS\t\tOR\t017\t\t\t99178\t1104\t1110\t" \
                              "America/Los_Angeles\t2024-02-15\n1\tNowhere\tNowhere\t\t0\t0\tP\tPPL\tXX\t\t\t\t\t\t0\t\t0\t\t2024-01-01\n",
      'zip/allCountries.zip' => "US\t97701\tBend\tOregon\tOR\tDeschutes\t017\t\t\t44.0848\t-121.2969\t4\nUS\tbroken\n",
      'zip/CA_full.csv.zip' => "CA\tT2P 1J9\tCalgary\tAlberta\tAB\t\t\t\t\t51.0475\t-114.0708\t6\n",
      'zip/GB_full.csv.zip' => "\t\t\t\t\t\t\t\t\t\t\t\n",
      'zip/NL_full.csv.zip' => ''
    }
  end
  let(:path) { Rails.root.join('tmp/geo_names_build_test.sqlite3') }
  let(:database) { SQLite3::Database.new(path.to_s, results_as_hash: true) }
  let(:status) { instance_double(Process::Status, exitstatus: 0, success?: true) }

  before do
    lines.each do |file, text|
      allow(IO).to(receive(:popen).with(['unzip', '-p', "/data/geo_names/#{file}"]).and_yield(StringIO.new(text)))
    end
    allow(Process).to(receive(:last_status).and_return(status))
  end

  after { FileUtils.rm_f(path) }

  describe '.source' do
    it { expect(described_class.source).to(eq('https://download.geonames.org/export')) }
  end

  describe '#call' do
    it { expect(geo_names_build.call).to(eq(cities: 1, postal_codes: 2)) }

    it do
      geo_names_build.call

      expect(database.execute('SELECT id, name, country_code, admin_code1, population, time_zone FROM cities')).to(
        eq([{
             'admin_code1' => 'OR', 'country_code' => 'US', 'id' => 5_713_587, 'name' => 'Bend', 'population' => 99_178,
             'time_zone' => 'America/Los_Angeles'
           }])
      )
    end

    it do
      geo_names_build.call

      expect(database.execute('SELECT postal_code, place_name, admin_code1, accuracy FROM postal_codes')).to(
        contain_exactly(
          { 'accuracy' => 4, 'admin_code1' => 'OR', 'place_name' => 'Bend', 'postal_code' => '97701' },
          { 'accuracy' => 6, 'admin_code1' => 'AB', 'place_name' => 'Calgary', 'postal_code' => 'T2P 1J9' }
        )
      )
    end

    it do
      geo_names_build.call

      expect(database.execute('SELECT * FROM releases')).to(eq([{ 'name' => '2026-11', 'schema_version' => GeoNames::Schema.version }]))
    end

    it do
      geo_names_build.call

      expect(GeoNames::PostalCode.connection_db_config.database).to(eq('tmp/geo_names_test.sqlite3'))
    end

    context 'when unzip fails' do
      let(:status) { instance_double(Process::Status, exitstatus: 9, success?: false) }

      it { expect { geo_names_build.call }.to(raise_error(Providers::Error, 'unzip exited with 9')) }

      it do
        expect { geo_names_build.call }.to(raise_error(Providers::Error))

        expect(File).not_to(exist(path))
      end
    end
  end
end
