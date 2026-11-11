module Overture
  class PlaceSearch
    LOCATION_INDEX = 'places INDEXED BY index_places_on_latitude_and_longitude'.freeze
    NOTHING = { id_null: true }.freeze

    attr_reader :filter, :sort

    def initialize(filter: nil, sort: [])
      @filter = filter.to_h
      @sort = sort
    end

    def call = scope.ransack(conditions(filter).merge(s: sort)).result.order(:id)

    private

    def conditions(filter)
      groups = [freight_kit_condition(filter[:freight_kit_location_types_in]), or_condition(filter[:or])].compact

      filter.except(:freight_kit_location_types_in, :or).merge(g: groups)
    end

    def freight_kit_condition(names)
      return if names.nil?

      categories = FreightKitLocationTypes.provider_types(Providers::Overture.key, names)
      categories.any? ? { basic_category_in: categories } : NOTHING
    end

    def or_condition(filters) = ({ g: filters.map { conditions(it.to_h) }, m: 'or' } unless filters.nil?)
    def scope = filter.keys.any? { it.start_with?('latitude_') } ? Place.from(LOCATION_INDEX) : Place.all
  end
end
