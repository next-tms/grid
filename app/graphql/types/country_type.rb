module Types
  class CountryType < Types::BaseObject
    description 'An ISO 3166-1 country, with its postal code rules and regions.'

    POSTAL_CODE_LABELS = {
      'AT' => 'PLZ',
      'BR' => 'CEP',
      'CH' => 'PLZ',
      'DE' => 'PLZ',
      'GB' => 'Postcode',
      'IE' => 'Eircode',
      'IN' => 'PIN',
      'IT' => 'CAP',
      'US' => 'ZIP'
    }.freeze

    field :alpha2, String, null: false, description: 'The ISO 3166-1 alpha-2 code.'
    field :alpha3, String, null: true, description: 'The ISO 3166-1 alpha-3 code.'
    field :name, String, null: false, description: 'The ISO 3166-1 short name.', method: :iso_short_name
    field :numeric, Integer, null: true, description: 'The ISO 3166-1 numeric code.'
    field :postal_code, Boolean, null: false, description: 'Whether the country uses postal codes.'
    field :postal_code_format, String, null: true, description: 'An unanchored regular expression that matches a valid postal code.'
    field :postal_code_label, String, null: false, description: 'The local name of a postal code, such as "ZIP".'
    field :regions, [Types::RegionType], null: false, description: 'The ISO 3166-2 subdivisions.'

    def numeric = object.number&.to_i
    def postal_code = object.postal_code || false
    def postal_code_format = (object.data['postal_code_format'] if postal_code)
    def postal_code_label = POSTAL_CODE_LABELS.fetch(object.alpha2, 'Postal code')

    def regions
      object.subdivisions.map do |abbreviation, subdivision|
        { abbreviation:, iso3166_2: "#{object.alpha2}-#{abbreviation}", name: subdivision.name }
      end
    end
  end
end
