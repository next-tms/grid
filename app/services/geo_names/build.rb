module GeoNames
  class Build
    class << self
      # @see https://download.geonames.org/export/dump/readme.txt CC BY 4.0, credit GeoNames
      # @see https://download.geonames.org/export/zip/readme.txt CC BY 4.0, credit GeoNames, and Royal Mail for GB
      def source = 'https://download.geonames.org/export'
    end

    BATCH_SIZE = 10_000
    CITY_COLUMNS = {
      'id' => 0, 'name' => 1, 'latitude' => 4, 'longitude' => 5, 'country_code' => 8, 'admin_code1' => 10,
      'population' => 14, 'time_zone' => 17
    }.freeze
    CITY_FIELD_COUNT = 19
    CITY_FILES = ['dump/cities500.zip'].freeze
    POSTAL_CODE_COLUMNS = ['country_code', 'postal_code', 'place_name', 'admin_name1', 'admin_code1', 'admin_name2', 'admin_code2',
                           'admin_name3', 'admin_code3', 'latitude', 'longitude', 'accuracy'].freeze
    POSTAL_CODE_FILES = ['zip/allCountries.zip', 'zip/CA_full.csv.zip', 'zip/GB_full.csv.zip', 'zip/NL_full.csv.zip'].freeze

    attr_reader :path, :release, :source

    def initialize(path:, release:, source: self.class.source)
      @path = path.to_s
      @release = release
      @source = source
    end

    def call
      FileUtils.rm_f(building_path)
      Record.establish_connection(adapter: 'sqlite3', database: building_path)
      count = write
      Record.remove_connection
      File.rename(building_path, path)
      count
    ensure
      Record.establish_connection(:geo_names)
      FileUtils.rm_f(building_path)
    end

    private

    def building_path = "#{path}.building"

    def city(line)
      values = line.chomp.split("\t", -1)
      return if values.size != CITY_FIELD_COUNT

      row = CITY_COLUMNS.transform_values { values[it].squish.presence }
      row if row.values_at('country_code', 'latitude', 'longitude', 'time_zone').all?(&:present?)
    end

    def download(file, directory)
      return File.join(source, file) unless source.start_with?('http')

      uri = URI("#{source}/#{file}")
      File.join(directory, File.basename(file)).tap do |destination|
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          http.request_get(uri.request_uri) do |response|
            raise(Providers::Error, "geo_names responded #{response.code} for #{file}") unless response.is_a?(Net::HTTPSuccess)

            File.open(destination, 'wb') { |io| response.read_body { io.write(it) } }
          end
        end
      end
    end

    def insert(model, files, &)
      rows(files).each_slice(BATCH_SIZE).sum do |batch|
        records = batch.filter_map(&)
        model.insert_all(records) if records.any?
        records.size
      end
    end

    def postal_code(line)
      values = line.chomp.split("\t", -1).map { it.squish.presence }
      return if values.size != POSTAL_CODE_COLUMNS.size

      row = POSTAL_CODE_COLUMNS.zip(values).to_h
      row if row['country_code'].present? && row['postal_code'].present?
    end

    def rows(files)
      Enumerator.new do |rows|
        Dir.mktmpdir do |directory|
          files.each do |file|
            IO.popen(['unzip', '-p', download(file, directory)]) { |io| io.each_line { rows << it } }
            raise(Providers::Error, "unzip exited with #{Process.last_status&.exitstatus}") unless Process.last_status&.success?
          end
        end
      end
    end

    def write
      Schema.define(Record.connection)
      counts = { cities: insert(City, CITY_FILES) { city(it) }, postal_codes: insert(PostalCode, POSTAL_CODE_FILES) { postal_code(it) } }
      Release.create!(name: release, schema_version: Schema.version)
      [City, PostalCode, Release].each(&:reset_column_information)
      counts
    end
  end
end
