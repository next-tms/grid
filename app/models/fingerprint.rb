module Fingerprint
  class << self
    def of(sources) = ActiveSupport::Digest.hexdigest(ActiveSupport::Cache.expand_cache_key([sources]))
  end
end
