module Providers
  class Smarty < Base
    class << self
      def authority = :certified
      # @see https://www.smarty.com/legal/terms-of-service Subscription Agreement 2.5, 6.6 and 7.2
      def cache_duration = 90.days
      def cost = :low
      def credential_keys = ['SMARTY_AUTH_ID', 'SMARTY_AUTH_TOKEN']
      def roles = %i[geocode time_zone verification]
    end

    GEOCODE_GRANULARITIES = {
      'Parcel' => 'PREMISE',
      'Rooftop' => 'PREMISE',
      'Street' => 'ROUTE',
      'Zip5' => 'OTHER',
      'Zip6' => 'OTHER',
      'Zip7' => 'BLOCK',
      'Zip8' => 'BLOCK',
      'Zip9' => 'BLOCK'
    }.freeze
    REGION_CODES = ['AS', 'FM', 'GU', 'MH', 'MP', 'PR', 'PW', 'US', 'VI'].freeze
    STREET_ENDPOINT = URI('https://us-street.api.smarty.com/street-address').freeze
    ZIP_CODE_ENDPOINT = URI('https://us-zipcode.api.smarty.com/lookup').freeze

    def call = query.street? ? street_validation : zip_code_validation
    def supports? = query.is_a?(AddressQuery) && REGION_CODES.include?(query.region_code) && (query.street? || query.postal_code.present?)

    private

    def credentials = { 'auth-id' => ENV.fetch('SMARTY_AUTH_ID'), 'auth-token' => ENV.fetch('SMARTY_AUTH_TOKEN') }
    def lookup(endpoint, params) = get_json(endpoint.dup.tap { it.query = params.compact_blank.merge(credentials).to_query }).first
    def rdi(metadata, value) = metadata[:rdi].presence&.eql?(value)
    def region_code(state_abbreviation) = REGION_CODES.excluding('US').include?(state_abbreviation) ? state_abbreviation : 'US'
    def state = query.administrative_area.presence || query.region_code.presence_in(REGION_CODES.excluding('US'))

    def street_params
      {
        'addressee' => query.organization,
        'candidates' => 1,
        'city' => query.locality,
        'features' => 'iana-timezone',
        'state' => state,
        'street' => query.address_lines.first,
        'street2' => query.address_lines.drop(1).join(' '),
        'zipcode' => query.postal_code
      }
    end

    def street_validation
      candidate = lookup(STREET_ENDPOINT, street_params)
      return if candidate.blank?

      components = candidate.fetch(:components, {})
      metadata = candidate.fetch(:metadata, {})
      dpv_confirmation = candidate.dig(:analysis, :dpv_match_code).presence

      build_validation(
        address_lines: [candidate[:delivery_line_1], candidate[:delivery_line_2]],
        administrative_area: components[:state_abbreviation],
        business: rdi(metadata, 'Commercial'),
        dpv_confirmation:,
        geocode_granularity: GEOCODE_GRANULARITIES[metadata[:precision]],
        latitude: metadata[:latitude],
        locality: components[:city_name],
        longitude: metadata[:longitude],
        po_box: metadata[:record_type] == 'P',
        postal_code: [components[:zipcode], components[:plus4_code]].compact_blank.join('-').presence,
        provider_identifier: candidate[:smarty_key],
        raw: candidate,
        region_code: region_code(components[:state_abbreviation]),
        residential: rdi(metadata, 'Residential'),
        time_zone: metadata[:iana_time_zone].presence_in(TZInfo::Timezone.all_identifiers),
        validation_granularity: validation_granularity(dpv_confirmation, components)
      )
    end

    def validation_granularity(dpv_confirmation, components)
      case dpv_confirmation
      when 'Y' then components[:secondary_number].present? ? 'SUB_PREMISE' : 'PREMISE'
      when 'D', 'S' then 'PREMISE'
      else 'ROUTE'
      end
    end

    def zip_code_validation
      result = lookup(ZIP_CODE_ENDPOINT, 'zipcode' => query.postal_code)
      zip_code = result&.dig(:zipcodes, 0)
      return if zip_code.blank?

      build_validation(
        administrative_area: zip_code[:state_abbreviation],
        geocode_granularity: 'OTHER',
        latitude: zip_code[:latitude],
        locality: zip_code[:default_city] || result.dig(:city_states, 0, :city),
        longitude: zip_code[:longitude],
        postal_code: zip_code[:zipcode],
        raw: result,
        region_code: region_code(zip_code[:state_abbreviation]),
        validation_granularity: 'OTHER'
      )
    end
  end
end
