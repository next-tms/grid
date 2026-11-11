module Overture
  class Build
    class << self
      # @see https://docs.overturemaps.org/attribution/ CDLA Permissive 2.0, and Apache 2.0 for Foursquare records
      def source(release) = "s3://overturemaps-us-west-2/release/#{release}/theme=places/type=place/*"
    end

    BATCH_SIZE = 10_000
    COLUMNS = ['id', 'name', 'basic_category', 'primary_category', 'operating_status', 'freeform', 'locality', 'region', 'postcode',
               'country', 'latitude', 'longitude'].freeze
    REGION_CODE = /\A[A-Z]{2}\z/

    attr_reader :path, :region_code, :release, :source

    def initialize(path:, region_code:, release:, source:)
      raise(ArgumentError, "Unknown region code '#{region_code}'") unless region_code.to_s.match?(REGION_CODE)

      @path = path.to_s
      @region_code = region_code
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
      Record.establish_connection(:overture)
      FileUtils.rm_f(building_path)
    end

    private

    def address_key(row)
      AddressKey.for(
        AddressQuery.new(
          address_lines: [row['freeform']],
          administrative_area: row['region'].to_s.delete_prefix("#{region_code}-"),
          locality: row['locality'],
          postal_code: row['postcode'],
          region_code:
        )
      )
    end

    def building_path = "#{path}.building"

    def record(row)
      row = row.transform_values { it.to_s.gsub(/[[:cntrl:]]/, '').squish.presence }
      address_key = address_key(row)
      return if address_key.blank? || row['id'].blank? || row['name'].blank?

      row.slice(*COLUMNS).merge('address_key' => address_key)
    end

    def rows
      Enumerator.new do |rows|
        IO.popen(['duckdb', '-csv', '-nullvalue', '', '-c', sql]) { |io| CSV.new(io, headers: true).each { rows << it.to_h } }
        raise(Providers::Error, "duckdb exited with #{Process.last_status&.exitstatus}") unless Process.last_status&.success?
      end
    end

    def sql
      <<~SQL
        INSTALL httpfs; LOAD httpfs; SET s3_region = 'us-west-2';
        SELECT
          id,
          names.primary AS name,
          basic_category,
          taxonomy.primary AS primary_category,
          operating_status,
          addresses[1].freeform AS freeform,
          addresses[1].locality AS locality,
          addresses[1].region AS region,
          addresses[1].postcode AS postcode,
          addresses[1].country AS country,
          bbox.ymin AS latitude,
          bbox.xmin AS longitude
        FROM read_parquet('#{source.gsub("'", "''")}', hive_partitioning = true)
        WHERE addresses[1].country = '#{region_code}'
      SQL
    end

    def write
      Schema.define(Record.connection)
      count = rows.each_slice(BATCH_SIZE).sum do |batch|
        records = batch.filter_map { record(it) }
        Place.insert_all(records) if records.any?
        records.size
      end
      Schema.index(Record.connection)
      Release.create!(name: release, schema_version: Schema.version)
      [Place, Release].each(&:reset_column_information)
      count
    end
  end
end
