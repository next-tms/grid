module Types
  module NodeType
    include Types::BaseInterface
    include GraphQL::Types::Relay::NodeBehaviors

    description 'An object with a Grid ID.'
  end
end
