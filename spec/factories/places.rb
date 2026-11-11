FactoryBot.define do
  factory :place do
    validation
    address { validation.validatable }

    name { 'Fake Cafe' }
  end
end
