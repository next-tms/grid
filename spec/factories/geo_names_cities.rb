FactoryBot.define do
  factory :geo_names_city, class: 'GeoNames::City' do
    admin_code1 { 'OR' }
    country_code { 'US' }
    latitude { 44.05817 }
    longitude { -121.31531 }
    name { 'Bend' }
    population { 99_178 }
    time_zone { 'America/Los_Angeles' }
  end
end
