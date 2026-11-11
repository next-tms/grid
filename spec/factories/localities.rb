FactoryBot.define do
  factory :locality do
    administrative_area

    sequence(:name) { |n| "Locality #{n}" }
  end
end
