module Providers
  class << self
    def all = [*(Fake if Rails.env.local?), GeoNames, Google, OpenStreetMap, Overture, Smarty]

    def configured?(provider)
      return true if provider.configured?

      message = "#{provider.key} is disabled because #{provider.credential_keys.join(' or ')} is not set"
      Rails.logger.warn(message) if unconfigured.add?(provider)
      false
    end

    def enabled = keys.filter_map { find(it) }.select { configured?(it) }.sort_by.with_index { |provider, index| [*rank(provider), index] }
    def find(key) = all.find { it.key == key }
    def keys = ENV.fetch('GRID_PROVIDERS', '').split(',').map(&:strip).compact_blank
    def rank(provider) = [Base::AUTHORITIES.index(provider.authority), Base::COSTS.index(provider.cost)]
    def unconfigured = @unconfigured ||= Set.new
  end
end
