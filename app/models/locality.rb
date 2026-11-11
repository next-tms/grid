class Locality < ApplicationRecord
  belongs_to :administrative_area

  has_many :addresses, dependent: :restrict_with_error
  has_many :postal_codes, dependent: :nullify
  has_many :provider_identifiers, as: :identifiable, dependent: :destroy

  delegate :country, to: :administrative_area

  validates :name, presence: true, uniqueness: { scope: :administrative_area_id }
end
