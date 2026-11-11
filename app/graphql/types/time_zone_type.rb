module Types
  class TimeZoneType < Types::BaseObject
    description 'An IANA time zone.'

    field :authority, Types::AuthorityType, null: true, description: 'The provider authority, or null for tzdata.'
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true, description: 'When the provider result expires, or null for tzdata.'
    field :id, String, null: false, description: 'The IANA time zone name.', method: :name
  end
end
