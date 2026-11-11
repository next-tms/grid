module Types
  class AddressInputType < Types::BaseInputObject
    description 'A postal address with the field names of google.type.PostalAddress.'

    argument :address_lines, [String], required: false, description: 'The street lines.'
    argument :administrative_area, String, required: false, description: 'The state or province.'
    argument :locality, String, required: false, description: 'The city or town.'
    argument :postal_code, String, required: false, description: 'The postal code.'
    argument :region_code, String, required: true, description: 'The ISO 3166-1 alpha-2 country code.'
  end
end
