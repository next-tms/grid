module Types
  class QueryType < Types::BaseObject
    description 'The query root.'

    field :node, Types::NodeType, null: true, description: 'Fetches an object given its ID.' do
      argument :id, ID, required: true, description: 'ID of the object.'
    end

    field :nodes, [Types::NodeType, { null: true }], null: true, description: 'Fetches a list of objects given a list of IDs.' do
      argument :ids, [ID], required: true, description: 'IDs of the objects.'
    end

    field :fetch_place, Types::PlaceType, null: true, description: 'Fetches a place by its Grid ID or a provider ID.' do
      argument :id, Types::IdentifierInputType, required: true, description: 'The place ID.'
    end

    field :fetch_places, [Types::PlaceType], null: true, description: 'Fetches the places at an address.' do
      argument :address, Types::AddressInputType, required: true, description: 'The address.'
    end

    field :fetch_time_zone, Types::TimeZoneType, null: true, description: 'Fetches one time zone by address, IANA name, or location.' do
      argument :address, Types::AddressInputType, required: false, description: 'An address to verify and geocode first.'
      argument :id, String, required: false, description: 'The IANA time zone name.'
      argument :location, Types::LocationInputType, required: false, description: 'A point on the earth.'

      validates required: { one_of: %i[address id location] }
    end

    field :fetch_time_zones, [Types::TimeZoneType], null: false, description: 'Searches tzdata.' do
      argument :name, String, required: false, description: 'Part of an IANA or Active Support name, or a tzdata abbreviation.'
      argument :region_code, String, required: false, description: 'The ISO 3166-1 alpha-2 country code.'
    end

    field :overture_places, Types::OverturePlaceType.connection_type, null: false, description: 'Searches the Overture places file.' do
      argument :filter, Types::OverturePlaceFilterInputType, required: false, description: 'The conditions.'
      argument :sort, [Types::OverturePlaceSortType], required: false, description: 'The order, before the Overture ID.'
    end

    field :verify_address, Types::AddressVerificationType, null: true, description: 'Verifies and geocodes a postal address.' do
      argument :address, Types::AddressInputType, required: true, description: 'The address to verify.'
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    def fetch_place(id:)
      place = id.provider ? Place.identified_by(provider: id.provider, value: id.value).first : Place.find_by(id: id.value)
      return if place.blank?

      search_places(place.address).find { it.id == place.id }
    end

    def fetch_places(address:)
      search_places(AddressValidator.new(AddressQuery.new(**address)).address)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def fetch_time_zone(address: nil, id: nil, location: nil)
      return TimeZone.find(id) if id.present?
      return time_zone_at(location) if location.present?

      result = verify(address)
      time_zone_of(result) if result.present?
    end

    def fetch_time_zones(name: nil, region_code: nil) = TimeZoneSearch.new(name:, region_code:).call

    def overture_places(filter: nil, sort: [])
      raise(GraphQL::ExecutionError, 'The Overture places file is not available.') unless Overture::Place.available?

      Overture::PlaceSearch.new(filter:, sort:).call
    end

    def verify_address(address:) = verify(address)
  end
end
