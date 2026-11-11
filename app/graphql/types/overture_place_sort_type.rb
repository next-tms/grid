module Types
  class OverturePlaceSortType < Types::BaseEnum
    description 'An order for Overture places. Places with the same values stay in Overture ID order.'

    ['administrative_area', 'locality', 'name', 'postal_code'].product(['asc', 'desc']).each do |field, direction|
      description = "By #{field.humanize(capitalize: false)}, #{direction}ending."

      value("#{field}_#{direction}".upcase, value: "#{field} #{direction}", description:)
    end
  end
end
