module Types
  class GranularityType < Types::BaseEnum
    description 'How precise a geocode is, from SUB_PREMISE (a unit) to OTHER (a postal code or a city).'

    Validation::GEOCODE_GRANULARITIES.each { value(it, value: it) }
  end
end
