FactoryBot.define do
  factory :validation do
    validatable factory: :address

    address_lines { ['1600 Amphitheatre Pkwy'] }
    expires_at { 90.days.from_now }
    fetched_at { Time.current }
    provider { 'smarty' }
    region_code { 'US' }
  end
end
