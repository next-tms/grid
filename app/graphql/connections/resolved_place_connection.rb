module Connections
  class ResolvedPlaceConnection < GraphQL::Pagination::ActiveRecordRelationConnection
    attr_reader :provider

    def initialize(items, provider:, **)
      super(items, **)
      @provider = provider
    end

    private

    def load_page = PlaceResolver.new(provider, super).call
  end
end
