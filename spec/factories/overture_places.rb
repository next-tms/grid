FactoryBot.define do
  factory :overture_place, class: 'Overture::Place' do
    sequence(:id) { |n| "overture-#{n}" }
    address_key { '1600 AMPHITHEATRE PKWY, 94043, US' }
    basic_category { 'coffee_shop' }
    country { 'US' }
    locality { 'Mountain View' }
    name { 'Open Cafe' }
    postcode { '94043-1351' }
    region { 'CA' }
  end
end
