module Providers
  class Fake < Base
    class << self
      def authority = :commercial
      def cache_duration = 1.minute
      def cost = :free
      def roles = %i[business_details geocode time_zone verification]
    end

    LATITUDE = 37.42241
    LONGITUDE = -122.08561
    PLACES = [
      {
        name: 'Fake Cafe',
        permanently_closed: false,
        provider_identifier: 'fake-cafe',
        types: ['cafe', 'establishment', 'food', 'point_of_interest']
      },
      { name: 'Fake Office', permanently_closed: false, provider_identifier: 'fake-office', types: ['establishment', 'point_of_interest'] }
    ].freeze

    def call = query.street? ? street_validation : postal_code_validation
    def supports? = query.is_a?(Location) || query.street? || query.postal_code.present?
    def time_zone_name = 'America/Los_Angeles'

    private

    def postal_code_validation
      build_validation(
        administrative_area: 'CA',
        geocode_granularity: 'OTHER',
        latitude: 34.05224,
        locality: 'Los Angeles',
        longitude: -118.24368,
        postal_code: query.postal_code,
        region_code: query.region_code,
        validation_granularity: 'OTHER'
      )
    end

    def street_validation
      build_validation(
        address_lines: query.address_lines,
        administrative_area: query.administrative_area,
        business: true,
        dpv_confirmation: 'Y',
        geocode_granularity: 'PREMISE',
        latitude: LATITUDE,
        locality: query.locality,
        longitude: LONGITUDE,
        permanently_closed: false,
        po_box: false,
        place_details: PLACES,
        postal_code: query.postal_code,
        provider_identifier: "fake-#{query.key.parameterize}",
        region_code: query.region_code,
        residential: false,
        time_zone: time_zone_name,
        types: ['establishment', 'point_of_interest'],
        validation_granularity: 'PREMISE'
      )
    end
  end
end
