class Place < ApplicationRecord
  EMPTY_CONTENT = { name: nil, permanently_closed: nil, types: [] }.freeze

  belongs_to :address
  belongs_to :validation

  has_many :provider_identifiers, as: :identifiable, dependent: :destroy

  delegate :authority, :expires_at, :fetched_at, :provider, :stores_content?, to: :validation

  scope :identified_by, ->(provider:, value:) { joins(:provider_identifiers).where(provider_identifiers: { provider:, value: }) }

  validates :name, presence: true, if: -> { validation.present? && stores_content? }

  def freight_kit_location_types = FreightKitLocationTypes.for(provider, types)
end
