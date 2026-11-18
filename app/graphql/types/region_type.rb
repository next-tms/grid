module Types
  class RegionType < Types::BaseObject
    description 'An ISO 3166-2 subdivision of a country, such as a state or a province.'

    field :abbreviation, String, null: true, description: 'The subdivision part of the ISO 3166-2 code, such as "TX".'
    field :iso3166_2, String, null: false, description: 'The ISO 3166-2 code, such as "US-TX".'
    field :name, String, null: false, description: 'The subdivision name.'
  end
end
