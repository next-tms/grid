module GeoNames
  class Record < ApplicationRecord
    include DataFile

    class << self
      def releases = Release
      def schema = Schema
    end

    self.abstract_class = true

    connects_to database: { reading: :geo_names, writing: :geo_names }
  end
end
