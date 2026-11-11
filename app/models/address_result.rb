class AddressResult
  GEOCODE_PRECISION = ['SUB_PREMISE', 'PREMISE', 'PREMISE_PROXIMITY', 'BLOCK', 'ROUTE', 'OTHER'].freeze
  OFFICIAL_AUTHORITIES = %i[government postal_operator].freeze

  attr_reader :address, :query, :validations

  delegate :country, :place_id, to: :address
  delegate :id, to: :address, prefix: true

  def initialize(address:, query:, validations:)
    @address = address
    @query = query
    @validations = validations
  end

  def address_complete? = dpv_confirmation == 'Y' || validation&.authority.in?(OFFICIAL_AUTHORITIES)
  def address_lines = validation&.address_lines.presence || normalized_query.address_lines
  def administrative_area = validation ? validation.administrative_area : normalized_query.administrative_area
  def authority = AuthorityRange.of(field_authorities)
  def business = validation&.business
  def dock = validations.map(&:dock).compact.then { it.include?(true) || (false unless it.empty?) }
  def dpv_confirmation = validation&.dpv_confirmation
  def expires_at = validations.map(&:expires_at).min

  def formatted_address
    [*address_lines, locality, "#{administrative_area} #{postal_code}".strip,
     region_code == 'US' ? 'USA' : country.name].compact_blank.join(', ')
  end

  def geocode = validations.select(&:latitude).min_by.with_index { |validation, index| [precision(validation), index] }
  def geocode_granularity = geocode&.geocode_granularity || 'OTHER'
  def inferred_components? = validation.present? && inferred_fields.any?
  def input_granularity = query.street? ? 'PREMISE' : 'OTHER'
  def locality = validation ? validation.locality : normalized_query.locality

  def location
    return if geocode.blank?

    Location.new(
      authority: geocode.authority,
      granularity: geocode.geocode_granularity,
      latitude: geocode.latitude.to_f,
      longitude: geocode.longitude.to_f
    )
  end

  def normalized_query = @normalized_query ||= AddressNormalizer.new(query).call
  def po_box = validation&.po_box
  def postal_code = validation ? validation.postal_code : normalized_query.postal_code
  def region_code = validation&.region_code || query.region_code
  def replaced_components? = validation.present? && replaced_fields.any?
  def residential = validation&.residential
  def smarty_street_address = smarty_raw(:delivery_line_1)
  def smarty_zip_code = smarty_raw(:zipcodes)

  def time_zone
    source = validations.find { it.time_zone.present? }
    return if source.blank?

    TimeZone.new(expires_at: source.expires_at, fetched_at: source.fetched_at, name: source.time_zone, provider: source.provider)
  end

  def unconfirmed_components? = !address_complete?
  def validation = validations.find(&:validation_granularity)
  def validation_granularity = validation&.validation_granularity || 'OTHER'

  private

  def field_authorities
    return [:local] if validation.blank?

    [validation.authority, *(:local if validation.address_lines.blank? && normalized_query.address_lines.any?)]
  end

  def inferred_fields = %i[administrative_area locality postal_code].select { query.public_send(it).blank? && public_send(it).present? }
  def precision(validation) = GEOCODE_PRECISION.index(validation.geocode_granularity) || GEOCODE_PRECISION.size

  def replaced_fields
    %i[administrative_area locality postal_code].select do |field|
      input = query.public_send(field)
      output = public_send(field)
      input.present? && output.present? && !output.upcase.start_with?(input.upcase)
    end
  end

  def smarty_raw(key) = validations.find { it.provider == 'smarty' && it.raw.key?(key) }&.raw
end
