module GeoNames
  class PostalCode < Record
    class << self
      def lookup(region_code, postal_code)
        Schema.postal_codes_for(region_code, postal_code).lazy.filter_map do
          where(country_code: region_code, postal_code: it).order(:id).first
        end.first
      end
    end

    self.table_name = 'postal_codes'

    def lookup_result = { admin_code1:, country_code:, lat: latitude, lng: longitude, place_name:, postalcode: postal_code }
  end
end
