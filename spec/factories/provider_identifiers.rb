FactoryBot.define do
  factory :provider_identifier do
    identifiable factory: :locality

    provider { 'geo_names' }
    sequence(:value) { |n| "place-#{n}" }
  end
end
