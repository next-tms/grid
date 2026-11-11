class PostalCode < ApplicationRecord
  before_validation :set_country, if: -> { locality.present? }

  belongs_to :country
  belongs_to :locality, optional: true

  has_many :addresses, dependent: :restrict_with_error
  has_many :provider_identifiers, as: :identifiable, dependent: :destroy

  normalizes :value, with: -> { it.squish.upcase }

  validate :validate_locality_belongs_to_country, if: -> { country.present? && locality.present? }

  validates :value, presence: true, uniqueness: { scope: :country_id }

  private

  def set_country = self.country ||= locality.country

  def validate_locality_belongs_to_country
    return if locality.country == country

    errors.add(:locality, :invalid)
  end
end
