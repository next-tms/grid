class ProviderIdentifier < ApplicationRecord
  belongs_to :identifiable, polymorphic: true

  validates :provider, presence: true, uniqueness: { scope: %i[identifiable_type identifiable_id] }
  validates :value, presence: true, uniqueness: { scope: %i[identifiable_type provider] }
end
