FactoryBot.define do
  factory :address do
    administrative_area
    country { administrative_area.country }
    locality { association(:locality, administrative_area:) }
    postal_code { association(:postal_code, locality:) }

    address_lines { ['1600 Amphitheatre Pkwy'] }
    sequence(:key) { |n| "1600 amphitheatre pkwy #{n}" }
  end
end
