module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    private

    def search_places(address)
      context[:places] ||= {}
      context[:places][address.id] ||= PlaceSearch.new(address).call
    end

    def time_zone_at(location)
      TimeZoneLookup.new(location).call
    rescue Providers::Error => e
      Sentry.capture_exception(e)
      raise(GraphQL::ExecutionError, e.message)
    end

    def time_zone_of(result) = result.time_zone || (result.location && time_zone_at(result.location))

    def verify(address)
      AddressValidator.new(AddressQuery.new(**address)).call
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
