module Types
  class PlaceType < Types::BaseObject
    description 'A business or other place at an address.'

    field :address_id, ID, null: true, description: 'The Grid address ID, or null until Grid stores the place.'
    field :address_lines, [String], null: false, description: 'The street lines.'
    field :administrative_area, String, null: true, description: 'The state or province.'
    field :authority, Types::AuthorityType, null: false, description: 'The authority of the source.'
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: false, description: 'When the source expires.'
    field :fingerprint, String, null: false, description: 'A digest of the source, which changes only when the source changes.'
    field :freight_kit_location_types, [Types::FreightKitLocationTypeType], null: false, description: 'The FreightKit location types.'
    field :id, ID, null: false, description: 'The Grid place ID.'
    field :locality, String, null: true, description: 'The city or town.'
    field :location, Types::LocationType, null: true, description: 'The geocode of the address from the source.'
    field :name, String, null: false, description: 'The name of the place.'
    field :permanently_closed, Boolean, null: true, description: 'Whether the place is permanently closed.'
    field :postal_code, String, null: true, description: 'The postal code.'
    field :provider, Types::ProviderType, null: false, description: 'The provider of the place. Do not store GOOGLE content.'
    field :region_code, String, null: false, description: 'The ISO 3166-1 alpha-2 country code.'
    field :types, [String], null: false, description: 'The place types in the vocabulary of the provider.'

    def fingerprint = Fingerprint.of([object.fingerprint_source])
  end
end
