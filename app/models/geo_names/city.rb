module GeoNames
  class City < Record
    class << self
      def nearest(latitude, longitude)
        SEARCH_RADII.lazy.filter_map do |radius|
          where(latitude: (latitude - radius)..(latitude + radius), longitude: (longitude - radius)..(longitude + radius))
            .min_by { it.distance_to(latitude, longitude) }
        end.first
      end
    end

    SEARCH_RADII = [0.25, 1, 4].freeze

    self.table_name = 'cities'

    def distance_to(other_latitude, other_longitude)
      Math.hypot(latitude - other_latitude, (longitude - other_longitude) * Math.cos(other_latitude * Math::PI / 180))
    end
  end
end
