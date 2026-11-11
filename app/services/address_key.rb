module AddressKey
  class << self
    def for(query)
      normalizer = AddressNormalizer.new(query)
      street = normalizer.street_line
      postal_code = normalizer.call.postal_code.to_s.split('-').first

      [street, postal_code, query.region_code].join(', ') if street.present? && postal_code.present?
    end
  end

  FILES = ['app/services/address_key.rb', 'app/services/address_normalizer.rb', 'config/usps_publication_28.yml'].freeze
end
