FactoryBot.define do
  factory :geo_names_postal_code, class: 'GeoNames::PostalCode' do
    accuracy { 4 }
    admin_code1 { 'OR' }
    admin_name1 { 'Oregon' }
    country_code { 'US' }
    latitude { 44.0848 }
    longitude { -121.2969 }
    place_name { 'Bend' }
    postal_code { '97701' }
  end
end
