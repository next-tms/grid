module Types
  class PlaceSortType < Types::BaseEnum
    description 'An order for places. Places with the same values keep a stable order.'

    ['administrative_area', 'locality', 'name', 'postal_code'].product(['asc', 'desc']).each do |field, direction|
      description = "By #{field.humanize(capitalize: false)}, #{direction}ending."

      value("#{field}_#{direction}".upcase, value: "#{field} #{direction}", description:)
    end
  end
end
