module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    private

    def record_sources(sources) = context[:sources]&.concat(sources)

    def search_places(address)
      context[:places] ||= {}
      context[:places][address.id] ||= PlaceSearch.new(address).then { |search| search.call.tap { record_sources(search.sources) } }
    end

    def time_zone_at(location)
      TimeZoneLookup.new(location).call.tap { record_sources([it].compact) }
    rescue Providers::Error => e
      Sentry.capture_exception(e)
      raise(GraphQL::ExecutionError, e.message)
    end

    def time_zone_of(result) = result.time_zone || (result.location && time_zone_at(result.location))

    def verify(address)
      AddressValidator.new(AddressQuery.new(**address)).call.tap { record_sources(it.validations) }
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
