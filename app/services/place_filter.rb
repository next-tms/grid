class PlaceFilter
  ROLES = %i[place_search].freeze

  attr_reader :filter, :providers, :sort

  def initialize(filter: nil, sort: [], providers: Providers.enabled)
    @filter = filter
    @providers = providers.select { it.roles.intersect?(ROLES) }
    @sort = sort
  end

  def call = provider&.place_search(filter:, sort:)
  def provider = @provider ||= providers.find(&:place_search?)
end
