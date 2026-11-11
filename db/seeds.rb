def seed(name) = YAML.load_file(Rails.root.join("db/seed/#{name}.yaml"), symbolize_names: true)

seed(:countries).each { |attributes| Country.find_or_initialize_by(iso3166_1_alpha2: attributes[:iso3166_1_alpha2]).update!(attributes) }

countries = Country.all.index_by(&:iso3166_1_alpha2)

seed(:administrative_areas).each do |attributes|
  country = countries.fetch(attributes.delete(:country_iso3166_1_alpha2))

  AdministrativeArea.find_or_initialize_by(country:, name: attributes[:name]).update!(attributes)
end
