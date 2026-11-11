FactoryBot.define do
  factory :postal_code do
    country { locality ? locality.country : association(:country) }
    locality

    sequence(:value) { |n| format('%05d', n) }
  end
end
