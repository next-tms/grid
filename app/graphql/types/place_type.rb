module Types
  class PlaceType < Types::BaseObject
    description 'A business or other place at an address.'

    field :authority, Types::AuthorityType, null: false, description: 'The authority of the source.'
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'When the source expires.'
    field :freight_kit_location_types, [Types::FreightKitLocationTypeType], null: false, description: 'The FreightKit location types.'
    field :id, ID, null: false, description: 'The Grid place ID.'
    field :name, String, null: false, description: 'The name of the place.'
    field :permanently_closed, Boolean, null: true, description: 'Whether the place is permanently closed.'
    field :provider, Types::ProviderType, null: false, description: 'The provider of the place. Do not store GOOGLE content.'
    field :types, [String], null: false, description: 'The place types in the vocabulary of the provider.'
  end
end
