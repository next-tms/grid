class Country < ApplicationRecord
  extend Mobility

  has_many :addresses, dependent: :restrict_with_error
  has_many :administrative_areas, dependent: :destroy
  has_many :postal_codes, dependent: :destroy

  has_many :localities, through: :administrative_areas
  has_many :provider_identifiers, as: :identifiable, dependent: :destroy

  translates :name, type: :string

  validates :iso3166_1_alpha2, format: { with: /\A[A-Z]{2}\z/ }, uniqueness: true
  validates :iso3166_1_alpha3, format: { with: /\A[A-Z]{3}\z/ }, uniqueness: true
  validates :name, presence: true, uniqueness: true
  validates :un_m49, numericality: { in: 1..999, only_integer: true }, uniqueness: true

  def region_code = iso3166_1_alpha2
end
