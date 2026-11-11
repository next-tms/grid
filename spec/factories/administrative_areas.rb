FactoryBot.define do
  factory :administrative_area do
    country

    sequence(:name) { |n| "Administrative Area #{n}" }
  end
end
