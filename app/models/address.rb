class Address < ApplicationRecord
  class << self
    def from_place_id!(place_id)
      id = place_id.to_s.delete_prefix(PLACE_ID_PREFIX) if place_id.to_s.start_with?(PLACE_ID_PREFIX)
      return find(id) if id.present?

      ProviderIdentifier.find_by!(identifiable_type: name, provider: 'google', value: place_id).identifiable
    end
  end

  PLACE_ID_PREFIX = 'grid:'.freeze

  belongs_to :administrative_area, optional: true
  belongs_to :country
  belongs_to :locality, optional: true
  belongs_to :postal_code, optional: true

  has_many :places, dependent: :destroy
  has_many :provider_identifiers, as: :identifiable, dependent: :destroy
  has_many :validations, as: :validatable, dependent: :destroy

  normalizes :address_lines, with: ->(address_lines) { address_lines.filter_map { it&.squish.presence } }

  validate :validate_administrative_area_belongs_to_country, if: -> { administrative_area.present? && country.present? }
  validate :validate_locality_belongs_to_administrative_area, if: -> { administrative_area.present? && locality.present? }
  validate :validate_postal_code_belongs_to_country, if: -> { country.present? && postal_code.present? }

  validates :key, presence: true, uniqueness: true

  def place_id = "#{PLACE_ID_PREFIX}#{id}"

  def query
    validation = enabled_validations.where.not(validation_granularity: nil).order(:fetched_at).last
    return normalized_query if validation.blank?

    AddressQuery.new(
      address_lines: validation.address_lines.presence || address_lines,
      administrative_area: validation.administrative_area,
      locality: validation.locality,
      organization:,
      postal_code: validation.postal_code,
      region_code: country.region_code
    )
  end

  def residential? = enabled_validations.where.not(residential: nil).order(fetched_at: :desc).pick(:residential) || false

  def validation_for(provider, query = self.query)
    adapter = provider.new(query)
    return unless adapter.supports?

    stored = validations.unexpired.where(provider: provider.key).order(:fetched_at).last if provider.stores_content?
    stored || adapter.call&.tap { record(it) }
  rescue Providers::Error => e
    Rails.logger.warn(e.message)
    Sentry.capture_exception(e)
    nil
  end

  private

  def enabled_validations = validations.unexpired.where(provider: Providers.enabled.map(&:key))

  def normalized_query
    AddressQuery.new(
      address_lines:,
      administrative_area: administrative_area&.abbreviation,
      locality: locality&.name,
      organization:,
      postal_code: postal_code&.value,
      region_code: country.region_code
    )
  end

  def record(validation)
    content = validation.slice(*Validation::EMPTY_CONTENT.keys)

    transaction do
      validation.assign_attributes(Validation::EMPTY_CONTENT) unless validation.stores_content?
      validation.update!(validatable: self)
      record_provider_identifier(validation)
      validation.place_details.each { record_place(validation, it) }
      validations.where(provider: validation.provider).where.not(id: validation.id).destroy_all unless validation.stores_content?
    end

    validation.assign_attributes(content)
  end

  def record_place(validation, details)
    identifier = { provider: validation.provider, value: details.fetch(:provider_identifier) }
    content = details.except(:provider_identifier)
    place = Place.identified_by(**identifier).first || places.build

    place.update!(**(validation.stores_content? ? content : Place::EMPTY_CONTENT), address: self, validation:)
    place.provider_identifiers.find_or_create_by!(identifier)
    place.assign_attributes(content)
    validation.association(:places).add_to_target(place)
  end

  def record_provider_identifier(validation)
    return if validation.provider_identifier.blank?

    identifier = { identifiable_type: self.class.name, provider: validation.provider, value: validation.provider_identifier }
    return if ProviderIdentifier.where(identifier).where.not(identifiable_id: id).exists?

    provider_identifiers.find_or_initialize_by(provider: validation.provider).update!(value: validation.provider_identifier)
  end

  def validate_administrative_area_belongs_to_country
    return if administrative_area.country == country

    errors.add(:administrative_area, :invalid)
  end

  def validate_locality_belongs_to_administrative_area
    return if locality.administrative_area == administrative_area

    errors.add(:locality, :invalid)
  end

  def validate_postal_code_belongs_to_country
    return if postal_code.country == country

    errors.add(:postal_code, :invalid)
  end
end
