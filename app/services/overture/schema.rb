module Overture
  module Schema
    class << self
      def define(connection)
        connection.create_table(:places, id: :string) do |t|
          t.string(:name, null: false)
          t.string(:basic_category)
          t.string(:primary_category)
          t.string(:operating_status)
          t.string(:freeform)
          t.string(:locality)
          t.string(:region)
          t.string(:postcode)
          t.string(:country, null: false)
          t.float(:latitude)
          t.float(:longitude)
          t.string(:address_key, null: false, index: true)
        end
        connection.create_table(:releases, id: false) do |t|
          t.string(:name, null: false)
          t.string(:schema_version, null: false)
        end
      end

      def index(connection)
        INDEXES.each { connection.add_index(:places, it) }
        connection.execute('ANALYZE')
      end

      def version = Digest::SHA256.hexdigest(FILES.map { Rails.root.join(it).read }.join)[0, 12]
    end

    FILES = [*AddressKey::FILES, 'app/services/overture/schema.rb'].freeze
    INDEXES = [%i[basic_category country region], %i[country postcode], %i[country region locality], %i[latitude longitude]].freeze
  end
end
