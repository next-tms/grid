module Types
  class LocationInputType < Types::BaseInputObject
    description 'A point on the earth, as latitude and longitude or as a full Plus Code.'

    argument :latitude, Float, required: false, description: 'The latitude in degrees.',
                               validates: { numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 } }
    argument :longitude, Float, required: false, description: 'The longitude in degrees.',
                                validates: { numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 } }
    argument :plus_code, String, required: false, description: 'A full Plus Code, for example 849VCWC7+XQ.'

    validates required: { one_of: [:plus_code, %i[latitude longitude]] }

    def prepare
      return Location.new(latitude:, longitude:) if plus_code.blank?

      latitude, longitude = PlusCode.decode(plus_code)
      raise(GraphQL::ExecutionError, 'plusCode must be a full Plus Code') if latitude.blank?

      Location.new(latitude:, longitude:)
    end
  end
end
