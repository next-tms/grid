module JSONKeys
  class << self
    def parse(source) = underscore(JSON.parse(source))

    def underscore(value)
      case value
      when Array then value.map { underscore(it) }
      when Hash then value.to_h { |key, nested| [key.to_s.underscore.to_sym, underscore(nested)] }
      else value
      end
    end
  end

  LOWER_CAMEL_CASE = ->(key) { key.gsub(/_([a-z\d])/) { it[1].upcase } }
end
