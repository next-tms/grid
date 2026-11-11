module Overture
  class Place < Record
    class << self
      def ransackable_associations(_auth_object = nil) = []
      def ransackable_attributes(_auth_object = nil) = [*column_names.excluding('address_key'), *_ransack_aliases.keys]
    end

    self.table_name = 'places'

    ransack_alias :address_line, :freeform
    ransack_alias :administrative_area, :region
    ransack_alias :postal_code, :postcode
    ransack_alias :region_code, :country

    delegate :authority, to: Providers::Overture

    def address_lines = [freeform].compact
    def freight_kit_location_types = FreightKitLocationTypes.for(Providers::Overture.key, types)

    def location
      return if latitude.blank? || longitude.blank?

      Location.new(authority:, granularity: 'PREMISE_PROXIMITY', latitude:, longitude:)
    end

    def permanently_closed = operating_status.presence && operating_status == 'permanently_closed'
    def place_details = { name:, permanently_closed:, provider_identifier: id, types: }
    def types = [basic_category, primary_category].compact_blank.uniq
  end
end
