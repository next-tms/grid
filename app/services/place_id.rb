module PlaceId
  class << self
    def for(provider, value) = Digest::UUID.uuid_v5(NAMESPACE, "#{provider}:#{value}")
  end

  FILES = ['app/services/place_id.rb'].freeze
  NAMESPACE = 'ec09ca87-20dc-4257-8f59-5def89783418'.freeze
end
