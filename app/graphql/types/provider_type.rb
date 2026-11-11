module Types
  class ProviderType < Types::BaseEnum
    description 'A provider that Grid can ask.'

    Providers.all.map(&:key).each { value(it.upcase, value: it) }
  end
end
