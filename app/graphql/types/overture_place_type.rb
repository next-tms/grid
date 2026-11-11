module Types
  class OverturePlaceType < Types::BaseObject
    description 'A place in the Overture places file, with its Overture data.'

    field :address_lines, [String], null: false, description: 'The street lines as Overture has them.'
    field :administrative_area, String, null: true, description: 'The state or province.', method: :region
    field :authority, Types::AuthorityType, null: false, description: 'The authority of Overture.'
    field :basic_category, String, null: true, description: 'The Overture basic category.'
    field :freight_kit_location_types, [Types::FreightKitLocationTypeType], null: false, description: 'The FreightKit location types.'
    field :id, ID, null: false, description: 'The Overture place ID.'
    field :locality, String, null: true, description: 'The city or town.'
    field :location, Types::LocationType, null: true, description: 'The point of the place.'
    field :name, String, null: false, description: 'The name of the place.'
    field :operating_status, String, null: true, description: 'The Overture operating status.'
    field :permanently_closed, Boolean, null: true, description: 'Whether the place is permanently closed.'
    field :postal_code, String, null: true, description: 'The postal code.', method: :postcode
    field :primary_category, String, null: true, description: 'The Overture primary category.'
    field :region_code, String, null: false, description: 'The ISO 3166-1 alpha-2 country code.', method: :country
    field :types, [String], null: false, description: 'The place types in the vocabulary of Overture.'
  end
end
