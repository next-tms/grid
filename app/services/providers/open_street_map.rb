module Providers
  class OpenStreetMap < Base
    class << self
      def authority = :open_data
      # @see https://operations.osmfoundation.org/policies/nominatim/ ODbL, credit OpenStreetMap, 1 request a second on the public server
      def cache_duration = 90.days
      def cost = :free
      def roles = %i[business_details dock geocode]
    end

    DEFAULT_URL = 'https://nominatim.openstreetmap.org'.freeze
    DOCK_TAG = 'amenity=loading_dock'.freeze
    DOCK_VALUES = { 'no' => false, 'yes' => true }.freeze
    LIMIT = 10
    PLACE_CATEGORIES = ['amenity', 'craft', 'healthcare', 'industrial', 'leisure', 'office', 'shop', 'tourism'].freeze
    USER_AGENT = 'Grid (Next TMS)'.freeze

    def call
      results = get_json(endpoint, 'User-Agent' => USER_AGENT)
      result = results.first
      return if result.blank?

      docks, results = results.partition { tag(it) == DOCK_TAG }
      places, addresses = results.partition { place?(it) }
      granularity = geocode_granularity(result[:place_rank].to_i)

      build_validation(
        dock: (dock(docks, result) if granularity == 'PREMISE'),
        geocode_granularity: granularity,
        latitude: result[:lat],
        longitude: result[:lon],
        place_details: places.map { place_details(it) },
        provider_identifier: addresses.first&.then { provider_identifier(it) },
        raw: result,
        region_code: query.region_code
      )
    end

    def supports? = query.is_a?(AddressQuery) && query.region_code.present? && (query.street? || query.postal_code.present?)

    private

    def dock(docks, result)
      docks.any? { same_street_number?(it[:display_name]) } || DOCK_VALUES[result.dig(:extratags, :loading_dock).to_s.downcase]
    end

    def endpoint = URI.join(ENV.fetch('NOMINATIM_URL', DEFAULT_URL), '/search').tap { it.query = params.compact_blank.to_query }

    def geocode_granularity(place_rank)
      case place_rank
      when 30 then 'PREMISE'
      when 26..29 then 'ROUTE'
      else 'OTHER'
      end
    end

    def params
      {
        'city' => query.locality,
        'countrycodes' => query.region_code.downcase,
        'extratags' => 1,
        'format' => 'jsonv2',
        'limit' => LIMIT,
        'postalcode' => query.postal_code,
        'state' => query.administrative_area,
        'street' => query.address_lines.first
      }
    end

    def place?(result)
      return false unless query.street? && result[:name].present? && same_street_number?(result[:display_name])

      PLACE_CATEGORIES.include?(result[:category]) || FreightKitLocationTypes.for(self.class.key, [tag(result)]).any?
    end

    def place_details(result)
      {
        name: result[:name],
        permanently_closed: nil,
        provider_identifier: provider_identifier(result),
        types: [tag(result)]
      }
    end

    def provider_identifier(result) = "#{result[:osm_type]}/#{result[:osm_id]}"
    def tag(result) = "#{result[:category]}=#{result[:type]}"
  end
end
