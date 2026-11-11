class AddressValidator
  ROLES = %i[dock geocode verification].freeze

  attr_reader :providers, :query

  def initialize(query, providers: Providers.enabled)
    @providers = providers.select { it.roles.intersect?(ROLES) }
    @query = query
  end

  def call = AddressResult.new(address:, query:, validations:)

  def address
    @address ||= Address.find_or_create_by!(key: normalized_query.key) do |address|
      address.address_lines = normalized_query.address_lines
      address.administrative_area = administrative_area
      address.country = country
      address.locality = locality
      address.organization = normalized_query.organization
      address.postal_code = postal_code
    end
  end

  def country = @country ||= Country.find_by!(iso3166_1_alpha2:)
  def normalized_query = @normalized_query ||= AddressNormalizer.new(query).call

  private

  def administrative_area
    return if normalized_query.administrative_area.blank?

    country.administrative_areas.find_by(abbreviation: normalized_query.administrative_area)
  end

  def answers?(validation, role)
    case role
    when :dock then !validation.dock.nil?
    when :geocode then validation.latitude.present?
    else validation.validation_granularity.present?
    end
  end

  def iso3166_1_alpha2 = query.region_code

  def locality
    return if administrative_area.blank? || normalized_query.locality.blank?

    administrative_area.localities.find_or_create_by!(name: normalized_query.locality)
  end

  def missing_roles(validations) = ROLES.reject { |role| validations.any? { answers?(it, role) } }

  def postal_code
    return if normalized_query.postal_code.blank?

    country.postal_codes.find_or_create_by!(value: normalized_query.postal_code) { it.locality = locality }
  end

  def validations
    providers.each_with_object([]) do |provider, validations|
      missing = missing_roles(validations)
      break validations if missing.empty?
      next unless provider.roles.intersect?(missing)

      validation = address.validation_for(provider, query)
      validations << validation if validation.present?
    end
  end
end
