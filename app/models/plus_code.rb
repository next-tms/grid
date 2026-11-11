module PlusCode
  class << self
    def decode(code)
      code = code.to_s.upcase
      return unless code.match?(FORMAT)

      latitude, longitude = code.delete(SEPARATOR).chars.each_slice(2).reduce([0, 0]) do |(rows, columns), (row, column)|
        [(rows * BASE) + ALPHABET.index(row), (columns * BASE) + ALPHABET.index(column)]
      end
      return unless latitude < 180 * PAIR_RESOLUTION && longitude < 360 * PAIR_RESOLUTION

      [((latitude + 0.5) / PAIR_RESOLUTION) - 90, ((longitude + 0.5) / PAIR_RESOLUTION) - 180]
    end

    def encode(latitude, longitude)
      latitude = [((latitude.clamp(-90, 90) + 90) * PAIR_RESOLUTION).floor, (180 * PAIR_RESOLUTION) - 1].min
      longitude = (((longitude + 180) % 360) * PAIR_RESOLUTION).floor

      digits = PAIRS.times.flat_map do
        pair = [ALPHABET[longitude % BASE], ALPHABET[latitude % BASE]]
        latitude /= BASE
        longitude /= BASE
        pair
      end

      digits.reverse.join.insert(SEPARATOR_POSITION, SEPARATOR)
    end
  end

  ALPHABET = '23456789CFGHJMPQRVWX'.freeze
  BASE = 20
  FORMAT = /\A[#{ALPHABET}]{8}\+[#{ALPHABET}]{2}\z/
  PAIRS = 5
  PAIR_RESOLUTION = 8000
  SEPARATOR = '+'.freeze
  SEPARATOR_POSITION = 8
end
