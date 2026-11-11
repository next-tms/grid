module Types
  class AuthorityRangeType < Types::BaseObject
    description 'The highest and lowest authority among the sources of an answer.'

    field :highest, Types::AuthorityType, null: false, description: 'The authority of the best source.'
    field :lowest, Types::AuthorityType, null: false, description: 'The authority of the weakest source.'
    field :quality, Float, null: false, description: 'A quality from 0 to 1, like an HTTP q-value, where 1 is the best.'
  end
end
