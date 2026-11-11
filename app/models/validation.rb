class Validation < ApplicationRecord
  EMPTY_CONTENT = { geocode_granularity: nil, latitude: nil, longitude: nil, permanently_closed: nil, raw: {}, types: [] }.freeze
  GEOCODE_GRANULARITIES = ['BLOCK', 'OTHER', 'PREMISE', 'PREMISE_PROXIMITY', 'ROUTE', 'SUB_PREMISE'].freeze
  VALIDATION_GRANULARITIES = ['BLOCK', 'OTHER', 'PREMISE', 'PREMISE_PROXIMITY', 'ROUTE', 'SUB_PREMISE'].freeze

  belongs_to :validatable, polymorphic: true

  has_many :places, dependent: :destroy

  attribute :place_details, default: -> { [] }
  attribute :provider_identifier, :string

  normalizes :address_lines, with: ->(address_lines) { address_lines.filter_map { it&.squish.presence } }

  scope :unexpired, -> { where(expires_at: Time.current..) }

  validates :expires_at, presence: true
  validates :fetched_at, presence: true
  validates :geocode_granularity, inclusion: { in: GEOCODE_GRANULARITIES }, allow_nil: true
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validates :provider, presence: true
  validates :region_code, format: { with: /\A[A-Z]{2}\z/ }, allow_nil: true
  validates :validation_granularity, inclusion: { in: VALIDATION_GRANULARITIES }, allow_nil: true

  def authority = Providers.find(provider)&.authority
  def expired? = expires_at.past?
  def raw = super.deep_symbolize_keys
  def stores_content? = Providers.find(provider).then { it.blank? || it.stores_content? }
end
