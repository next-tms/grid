module Types
  class IdentifierInputType < Types::BaseInputObject
    description 'A Grid ID, or a provider ID with its provider.'

    argument :provider, Types::ProviderType, required: false, description: 'The provider that issued the ID, or null for a Grid ID.'
    argument :value, ID, required: true, description: 'The ID.'
  end
end
