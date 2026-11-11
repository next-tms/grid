Location = Data.define(:authority, :granularity, :latitude, :longitude) do
  class << self
    def parse(value)
      latitude, longitude = value.to_s.split(',', 2).map { Float(it.strip, exception: false) }
      return unless latitude&.between?(-90, 90) && longitude&.between?(-180, 180)

      new(latitude:, longitude:)
    end
  end

  def cache_key = [latitude.round(4), longitude.round(4)].join(',')
  def initialize(latitude:, longitude:, authority: nil, granularity: nil) = super
  def plus_code = PlusCode.encode(latitude, longitude)
end
