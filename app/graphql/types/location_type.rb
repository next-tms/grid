module Types
  class LocationType < Types::BaseObject
    description 'A point on the earth.'

    field :authority, Types::AuthorityType, null: true, description: 'The authority of the geocode source.'
    field :granularity, Types::GranularityType, null: true, description: 'How precise the geocode is, or null for an input point.'
    field :latitude, Float, null: false, description: 'The latitude in degrees.'
    field :longitude, Float, null: false, description: 'The longitude in degrees.'
    field :plus_code, String, null: false, description: 'The Plus Code (Open Location Code) of the point.'
  end
end
