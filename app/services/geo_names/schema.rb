module GeoNames
  module Schema
    class << self
      def define(connection)
        connection.create_table(:cities) do |t|
          t.string(:name)
          t.string(:country_code, null: false)
          t.string(:admin_code1)
          t.float(:latitude, null: false)
          t.float(:longitude, null: false)
          t.integer(:population)
          t.string(:time_zone, null: false)
          t.index(%i[latitude longitude])
        end
        connection.create_table(:postal_codes) do |t|
          t.string(:country_code, null: false)
          t.string(:postal_code, null: false)
          t.string(:place_name)
          t.string(:admin_name1)
          t.string(:admin_code1)
          t.string(:admin_name2)
          t.string(:admin_code2)
          t.string(:admin_name3)
          t.string(:admin_code3)
          t.float(:latitude)
          t.float(:longitude)
          t.integer(:accuracy)
          t.index(%i[country_code postal_code])
        end
        connection.create_table(:releases, id: false) do |t|
          t.string(:name, null: false)
          t.string(:schema_version, null: false)
        end
      end

      def postal_codes_for(region_code, postal_code)
        code = postal_code.to_s.upcase.squish
        return [] if code.blank?

        inward = INWARD_LENGTHS[region_code]
        code = "#{code[...-inward]} #{code[-inward..]}" if inward.present? && !code.include?(' ') && code.size > inward
        [code, code.split(/[\s-]/).first].uniq
      end

      def version = Digest::SHA256.hexdigest(FILES.map { Rails.root.join(it).read }.join)[0, 12]
    end

    FILES = ['app/services/geo_names/schema.rb'].freeze
    INWARD_LENGTHS = { 'CA' => 3, 'GB' => 3, 'NL' => 2 }.freeze
  end
end
