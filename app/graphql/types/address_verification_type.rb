module Types
  class AddressVerificationType < Types::BaseObject
    description 'The verified form of a postal address.'

    field :address_id, ID, null: false, description: 'The Grid address ID.'
    field :address_lines, [String], null: false, description: 'The standardized street lines.'
    field :administrative_area, String, null: true, description: 'The state or province.'
    field :authority, Types::AuthorityRangeType, null: false, description: 'The authority range of the address field sources.'
    field :business, Boolean, null: true, description: 'Whether the address is a business.'
    field :dock, Boolean, null: true, description: 'Whether the building has a loading dock, or null when unknown.'
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true, description: 'When the first source expires, or null for LOCAL.'
    field :locality, String, null: true, description: 'The city or town.'
    field :location, Types::LocationType, null: true, description: 'The geocoded point.'
    field :places, [Types::PlaceType], null: false, description: 'The places at the address.'
    field :po_box, Boolean, null: true, description: 'Whether the address is a PO box.'
    field :postal_code, String, null: true, description: 'The postal code.'
    field :residential, Boolean, null: true, description: 'Whether the address is residential.'
    field :time_zone, Types::TimeZoneType, null: true, description: 'The time zone from the verification or the geocoded point.'
    field :verified, Boolean, null: false, description: 'Whether an official source confirms the address.', method: :address_complete?

    def places = search_places(object.address)
    def time_zone = time_zone_of(object)
  end
end
