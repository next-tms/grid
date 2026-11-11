module FreightKitLocationTypes
  class << self
    def for(provider, types) = types.to_a.flat_map { index.dig(provider, it) || [] }.uniq.sort
    def names = table.keys.sort
    def provider_types(provider, names) = table.values_at(*names).compact.flat_map { it.fetch(provider, []) }.uniq.sort
    def table = @table ||= YAML.load_file(Rails.root.join('config/freight_kit_location_types.yml'))

    private

    def index
      @index ||= table.each_with_object({}) do |(type, sources), index|
        sources.each { |provider, values| values.each { ((index[provider] ||= {})[it] ||= []) << type } }
      end
    end
  end
end
