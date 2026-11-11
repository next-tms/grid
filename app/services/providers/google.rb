module Providers
  class Google < Base
    class << self
      def authority = :commercial
      # @see https://cloud.google.com/maps-platform/terms/maps-service-terms Places API: only place IDs may be stored
      def cache_duration = 0.seconds
      def cost = :high
      def credential_keys = ['GOOGLE_API_KEY']
      def roles = %i[business_details geocode]
      def stores_content? = false
    end

    ADDRESS_TYPES = ['premise', 'street_address', 'subpremise'].freeze
    FIELD_MASK = ['businessStatus', 'displayName', 'formattedAddress', 'id', 'location', 'types'].map { "places.#{it}" }.join(',').freeze
    PAGE_SIZE = 5
    SEARCH_ENDPOINT = URI('https://places.googleapis.com/v1/places:searchText').freeze

    def call
      results = post_json(SEARCH_ENDPOINT, search_body, headers).fetch(:places, []).select { same_street_number?(it[:formatted_address]) }
      return if results.empty?

      addresses, places = results.partition { it[:types].to_a.intersect?(ADDRESS_TYPES) }
      location = (addresses.first || results.first)[:location].to_h

      build_validation(
        geocode_granularity: geocode_granularity(addresses, location),
        latitude: location[:latitude],
        longitude: location[:longitude],
        permanently_closed: permanently_closed(results.first),
        place_details: places.map { place_details(it) },
        provider_identifier: addresses.first&.dig(:id),
        region_code: query.region_code,
        types: results.first[:types].to_a
      )
    end

    def supports? = query.is_a?(AddressQuery) && query.street?

    private

    def geocode_granularity(addresses, location)
      return if location.blank?

      addresses.any? ? 'PREMISE' : 'PREMISE_PROXIMITY'
    end

    def headers = { 'X-Goog-Api-Key' => ENV.fetch('GOOGLE_API_KEY'), 'X-Goog-FieldMask' => FIELD_MASK }
    def permanently_closed(result) = result[:business_status].presence&.eql?('CLOSED_PERMANENTLY')

    def place_details(result)
      {
        name: result.dig(:display_name, :text),
        permanently_closed: permanently_closed(result),
        provider_identifier: result.fetch(:id),
        types: result[:types].to_a
      }
    end

    def search_body = { 'pageSize' => PAGE_SIZE, 'regionCode' => query.region_code, 'textQuery' => query.key }.compact
  end
end
