module Providers
  class Overture < Base
    class << self
      def authority = :open_data
      def cache_duration = 1.day
      def cost = :free
      def roles = %i[business_details geocode verification]
    end

    def call
      return if places.empty?

      points = places.filter_map { [it.latitude, it.longitude] if it.latitude.present? && it.longitude.present? }

      build_validation(
        administrative_area: most_common(places.map { state(it.region) }),
        geocode_granularity: ('PREMISE_PROXIMITY' if points.any?),
        latitude: median(points.map(&:first)),
        locality: most_common(places.map(&:locality)),
        longitude: median(points.map(&:last)),
        place_details: places.map(&:place_details),
        postal_code: address_key.split(', ').second,
        region_code: query.region_code,
        validation_granularity: 'PREMISE'
      )
    end

    def supports? = query.is_a?(AddressQuery) && ::Overture::Place.available? && address_key.present?

    private

    def address_key = @address_key ||= AddressKey.for(query)
    def median(values) = (values.sort.then { (it[(it.size - 1) / 2] + it[it.size / 2]) / 2 } if values.any?)
    def most_common(values) = values.compact_blank.tally.max_by(&:last)&.first
    def places = @places ||= ::Overture::Place.where(address_key:).order(:name).to_a
    def state(region) = region.to_s.upcase.then { AddressNormalizer.tables.fetch('states').fetch(it, it) }
  end
end
