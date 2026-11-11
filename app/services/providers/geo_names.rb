module Providers
  class GeoNames < Base
    class << self
      def authority = :open_data
      # @see https://www.geonames.org/export/ CC BY 4.0, credit GeoNames, 10,000 credits a day
      def cache_duration = 90.days
      def configured? = super || ::GeoNames::PostalCode.available?
      def cost = :free
      def credential_keys = ['GEONAMES_USERNAME']
      def roles = %i[geocode time_zone verification]
    end

    POSTAL_CODE_ENDPOINT = URI('https://secure.geonames.org/postalCodeLookupJSON').freeze
    TIME_ZONE_ENDPOINT = URI('https://secure.geonames.org/timezoneJSON').freeze

    def call
      postal_code = file? ? file_postal_code : api_postal_code
      return if postal_code.blank?

      build_validation(
        administrative_area: postal_code[:admin_code1],
        geocode_granularity: 'OTHER',
        latitude: postal_code[:lat],
        locality: postal_code[:place_name],
        longitude: postal_code[:lng],
        postal_code: postal_code[:postalcode],
        raw: postal_code,
        region_code: postal_code[:country_code],
        validation_granularity: 'OTHER'
      )
    end

    def supports? = (query.is_a?(Location) || postal_code_query?) && (username? || file?)
    def time_zone_name = username? ? api_time_zone_name : ::GeoNames::City.nearest(query.latitude, query.longitude)&.time_zone

    private

    def api_postal_code = lookup(POSTAL_CODE_ENDPOINT, country: query.region_code, postalcode: query.postal_code).dig(:postalcodes, 0)
    def api_time_zone_name = lookup(TIME_ZONE_ENDPOINT, lat: query.latitude, lng: query.longitude)[:timezone_id].presence
    def file? = ::GeoNames::PostalCode.available?
    def file_postal_code = ::GeoNames::PostalCode.lookup(query.region_code, query.postal_code)&.lookup_result

    def postal_code_query? = query.is_a?(AddressQuery) && !query.street? && query.postal_code.present? && query.region_code.present?

    def lookup(endpoint, **params)
      response = get_json(endpoint.dup.tap { it.query = params.merge(username: ENV.fetch('GEONAMES_USERNAME')).to_query })
      raise(Error, "geo_names failed: #{response[:status][:message]}") if response[:status].present?

      response
    end

    def username? = ENV['GEONAMES_USERNAME'].present?
  end
end
