class PlaceDetails
  ROLES = %i[business_details].freeze

  attr_reader :address, :providers

  def initialize(address, providers: Providers.enabled)
    @address = address
    @providers = providers.select { it.roles.intersect?(ROLES) }
  end

  def call = providers.lazy.filter_map { address.validation_for(it) }.find { it.types.any? || !it.permanently_closed.nil? }
end
