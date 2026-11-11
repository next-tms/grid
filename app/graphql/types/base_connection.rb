module Types
  class BaseConnection < Types::BaseObject
    include GraphQL::Types::Relay::ConnectionBehaviors

    field :total_count, Integer, null: false, description: 'The number of items in all pages.'

    def total_count = object.items.size
  end
end
