class PlaceSearch
  ROLES = %i[business_details].freeze

  attr_reader :address, :providers, :sources

  def initialize(address, providers: Providers.enabled)
    @address = address
    @providers = providers.select { it.roles.intersect?(ROLES) }
    @sources = []
  end

  def call
    return [] if address.residential?

    providers.each do |provider|
      validation = address.validation_for(provider)
      next if validation.blank?

      sources << validation
      places = validation.places.sort_by { it.name.to_s }
      return places if places.any?
    end

    []
  end
end
