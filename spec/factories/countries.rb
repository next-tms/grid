FactoryBot.define do
  factory :country do
    sequence(:iso3166_1_alpha2) { |n| (('AA'..'ZZ').to_a - ['US'])[n] }
    sequence(:iso3166_1_alpha3) { |n| ('AAA'..'ZZZ').to_a[n] }
    sequence(:name) { |n| "Country #{n}" }
    sequence(:un_m49) { |n| n }
  end
end
