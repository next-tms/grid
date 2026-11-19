module Overture
  class Place < Record
    class << self
      def ransackable_associations(_auth_object = nil) = []
      def ransackable_attributes(_auth_object = nil) = [*column_names.excluding('address_key', 'grid_id'), *_ransack_aliases.keys]
    end

    self.table_name = 'places'

    ransack_alias :address_line, :freeform
    ransack_alias :administrative_area, :region
    ransack_alias :postal_code, :postcode
    ransack_alias :region_code, :country
    ransack_alias :type, :basic_category_or_primary_category

    def address_lines = [freeform].compact

    def address_query
      administrative_area = region.to_s.delete_prefix("#{country}-").presence

      AddressQuery.new(address_lines:, administrative_area:, locality:, postal_code: postcode, region_code: country)
    end

    def permanently_closed = operating_status.presence && operating_status == 'permanently_closed'
    def place_details = { name:, permanently_closed:, provider_identifier: id, types: }
    def types = [basic_category, primary_category].compact_blank.uniq
  end
end
