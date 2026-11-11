module Types
  class FreightKitLocationTypeType < Types::BaseEnum
    description 'A FreightKit location type. Each one is the location in the FreightKit accessorials <type>_delivery and <type>_pickup.'

    FreightKitLocationTypes.names.each { value(it.upcase, value: it) }
  end
end
