class TimeZoneLookup
  ROLES = %i[time_zone].freeze

  attr_reader :location, :providers

  def initialize(location, providers: Providers.enabled)
    @location = location
    @providers = providers.select { it.roles.intersect?(ROLES) }
  end

  def call = providers.lazy.filter_map { time_zone_for(it) }.find(&:name)

  private

  def time_zone_for(provider)
    adapter = provider.new(location)
    return unless adapter.supports?

    Rails.cache.fetch(['time_zone', provider.key, location.cache_key], expires_in: provider.cache_duration) do
      fetched_at = Time.current

      TimeZone.new(expires_at: fetched_at + provider.cache_duration, fetched_at:, name: adapter.time_zone_name, provider: provider.key)
    end
  end
end
