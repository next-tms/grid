class Place < ApplicationRecord
  EMPTY_CONTENT = { name: nil, permanently_closed: nil, types: [] }.freeze

  belongs_to :address
  belongs_to :validation

  has_many :provider_identifiers, as: :identifiable, dependent: :destroy

  delegate :authority, :expires_at, :fetched_at, :provider, :stores_content?, to: :validation

  scope :identified_by, ->(provider:, value:) { joins(:provider_identifiers).where(provider_identifiers: { provider:, value: }) }

  validates :name, presence: true, if: -> { validation.present? && stores_content? }

  def address_lines = validation.address_lines.presence || address&.address_lines.to_a
  def administrative_area = validation.administrative_area || address&.administrative_area&.abbreviation

  def fingerprint_source
    return validation if validation.persisted?

    [id, name, permanently_closed, types, validation.attributes.except('expires_at', 'fetched_at')]
  end

  def freight_kit_location_types = FreightKitLocationTypes.for(provider, types)
  def locality = validation.locality || address&.locality&.name

  def location
    return if validation.latitude.blank? || validation.longitude.blank?

    Location.new(authority:, granularity: validation.geocode_granularity, latitude: validation.latitude.to_f,
                 longitude: validation.longitude.to_f)
  end

  def postal_code = validation.postal_code || address&.postal_code&.value
  def region_code = validation.region_code || address&.country&.region_code
end
