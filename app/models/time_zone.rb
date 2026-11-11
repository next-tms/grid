TimeZone = Data.define(:expires_at, :fetched_at, :name, :provider) do
  class << self
    def find(name)
      TZInfo::Timezone.get(name)

      new(expires_at: nil, fetched_at: nil, name:, provider: nil)
    rescue TZInfo::InvalidTimezoneIdentifier
      nil
    end
  end

  def authority = Providers.find(provider)&.authority
  def stores_content? = Providers.find(provider).then { it.blank? || it.stores_content? }
end
