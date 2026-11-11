class AdministrativeArea < ApplicationRecord
  before_validation :set_abbreviation, if: -> { iso3166_2.present? }
  before_validation :set_country, if: -> { iso3166_2.present? }

  belongs_to :country

  has_many :addresses, dependent: :restrict_with_error
  has_many :localities, dependent: :destroy

  has_many :postal_codes, through: :localities
  has_many :provider_identifiers, as: :identifiable, dependent: :destroy

  validates :abbreviation, uniqueness: { allow_nil: true, scope: :country_id }
  validates :iso3166_2, format: { allow_nil: true, with: /\A[A-Z]{2}-[A-Z0-9]{1,3}\z/ }, uniqueness: { allow_nil: true }
  validates :name, presence: true, uniqueness: { scope: :country_id }

  private

  def set_abbreviation = self.abbreviation = iso3166_2.split('-').last
  def set_country = self.country = Country.find_by(iso3166_1_alpha2: iso3166_2.split('-').first)
end
