module Types
  class AuthorityType < Types::BaseEnum
    description 'How close a provider is to the organization that assigns addresses.'

    Providers::Base::AUTHORITIES.each { value(it.to_s.upcase, value: it) }
  end
end
