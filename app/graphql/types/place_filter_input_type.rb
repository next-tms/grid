module Types
  class PlaceFilterInputType < Types::BaseInputObject
    description 'Conditions on places. A place must match all of them.'

    FLOAT_FIELDS = ['latitude', 'longitude'].freeze
    FLOAT_PREDICATES = {
      'gt' => [Float, 'The %s is greater than the value.'],
      'gteq' => [Float, 'The %s is greater than or equal to the value.'],
      'lt' => [Float, 'The %s is less than the value.'],
      'lteq' => [Float, 'The %s is less than or equal to the value.']
    }.freeze
    STRING_FIELDS = ['address_line', 'administrative_area', 'locality', 'name', 'postal_code', 'region_code'].freeze
    STRING_PREDICATES = {
      'cont' => [String, 'The %s contains the value.'],
      'end' => [String, 'The %s ends with the value.'],
      'eq' => [String, 'The %s is the value.'],
      'in' => [[String], 'The %s is one of the values.'],
      'not_eq' => [String, 'The %s is not the value.'],
      'not_in' => [[String], 'The %s is none of the values.'],
      'null' => [Boolean, 'The %s is null when true, or not null when false.'],
      'start' => [String, 'The %s starts with the value.']
    }.freeze
    TYPE_FIELDS = ['type'].freeze
    TYPE_PREDICATES = STRING_PREDICATES.slice('cont', 'end', 'eq', 'in', 'start').transform_values do |type, text|
      [type, text.sub('The', 'A place')]
    end.freeze

    argument :freight_kit_location_types_in,
             [Types::FreightKitLocationTypeType],
             description: 'The place has one of these FreightKit location types.',
             required: false
    argument :or, [self], description: 'The place matches at least one of these filters.', required: false
    argument :permanently_closed,
             Boolean,
             description: 'The place is permanently closed when true, or not known to be closed when false.',
             required: false

    { FLOAT_FIELDS => FLOAT_PREDICATES, STRING_FIELDS => STRING_PREDICATES, TYPE_FIELDS => TYPE_PREDICATES }.each do |fields, predicates|
      fields.product(predicates.to_a).each do |field, (predicate, (type, text))|
        argument(:"#{field}_#{predicate}", type, required: false, description: format(text, field.humanize(capitalize: false)))
      end
    end
  end
end
