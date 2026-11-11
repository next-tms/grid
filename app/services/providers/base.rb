module Providers
  class Base
    class << self
      def authority = raise(NotImplementedError)
      def cache_duration = raise(NotImplementedError)
      def configured? = credential_keys.all? { ENV[it].present? }
      def cost = raise(NotImplementedError)
      def credential_keys = []
      def key = name.demodulize.underscore
      def roles = raise(NotImplementedError)
      def stores_content? = true
    end

    AUTHORITIES = %i[postal_operator government certified open_data commercial local].freeze
    COSTS = %i[free low medium high].freeze
    ROLES = %i[business_details dock geocode time_zone verification].freeze
    TIMEOUT = 5

    attr_reader :query

    def initialize(query)
      @query = query
    end

    def call = raise(NotImplementedError)
    def supports? = raise(NotImplementedError)
    def time_zone_name = raise(NotImplementedError)

    private

    def build_validation(**attributes)
      fetched_at = Time.current

      Validation.new(expires_at: fetched_at + self.class.cache_duration, fetched_at:, provider: self.class.key, **attributes)
    end

    def failure(response) = "#{self.class.key} responded #{response.code}: #{response.body.to_s.truncate(200)}"
    def get_json(uri, headers = {}) = request_json(uri) { it.get(uri.request_uri, headers) }

    def post_json(uri, body, headers = {})
      request_json(uri) { it.post(uri.request_uri, body.to_json, headers.merge('Content-Type' => 'application/json')) }
    end

    def request_json(uri, &)
      response = Net::HTTP.start(uri.host, uri.port, open_timeout: TIMEOUT, read_timeout: TIMEOUT, use_ssl: uri.scheme == 'https', &)
      raise(Error, failure(response)) unless response.is_a?(Net::HTTPSuccess)

      JSONKeys.parse(response.body)
    rescue JSON::ParserError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
      raise(Error, "#{self.class.key} failed: #{e.message}")
    end

    def same_street_number?(text) = query.address_lines.first.to_s.scan(/\d+/).all? { text.to_s.include?(it) }
  end
end
