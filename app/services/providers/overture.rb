module Providers
  class Overture < Base
    class << self
      def authority = :open_data
      def cache_duration = 1.day
      def cost = :free

      def place(record)
        fetched_at = Time.current
        query = record.address_query

        ::Place.new(id: record.grid_id, name: record.name, permanently_closed: record.permanently_closed, types: record.types,
                    validation: Validation.new(
                      address_lines: AddressNormalizer.new(query).call.address_lines,
                      administrative_area: state(query.administrative_area),
                      expires_at: fetched_at + cache_duration,
                      fetched_at:,
                      geocode_granularity: ('PREMISE_PROXIMITY' if record.latitude.present? && record.longitude.present?),
                      latitude: record.latitude,
                      locality: record.locality,
                      longitude: record.longitude,
                      postal_code: record.address_key.split(', ').second,
                      provider: key,
                      region_code: record.country,
                      validation_granularity: 'PREMISE'
                    ))
      end

      def place_search(filter:, sort:) = ::Overture::PlaceSearch.new(filter:, sort:).call
      def place_search? = ::Overture::Place.available?

      def record_place(id)
        return if id.provider.present? && id.provider != key

        record = ::Overture::Place.find_by(id.provider.present? ? { id: id.value } : { grid_id: id.value })
        return if record.blank?

        query = record.address_query
        AddressValidator.new(query).address.validation_for(self, query, refresh: true)
        ::Place.identified_by(provider: key, value: record.id).first
      end

      def roles = %i[business_details geocode place_search verification]
      def state(region) = region.to_s.upcase.then { AddressNormalizer.tables.fetch('states').fetch(it, it) }
    end

    def call
      return if places.empty?

      points = places.filter_map { [it.latitude, it.longitude] if it.latitude.present? && it.longitude.present? }

      build_validation(
        administrative_area: most_common(places.map { self.class.state(it.region) }),
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
  end
end
