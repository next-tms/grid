class AddressNormalizer
  class << self
    def tables = @tables ||= YAML.load_file(Rails.root.join('config/usps_publication_28.yml'))
  end

  APOSTROPHES = /['’]/
  PO_BOX = /\AP ?O ?BOX\b|\APOST OFFICE BOX\b/
  PUNCTUATION = %r{[^\p{Alnum}\s#/-]}
  REGION_CODES = ['AS', 'FM', 'GU', 'MH', 'MP', 'PR', 'PW', 'US', 'VI'].freeze
  ZIP_CODE = /\A(\d{5})-?(\d{4})?\z/

  attr_reader :query

  def initialize(query)
    @query = query
  end

  def call
    AddressQuery.new(
      address_lines: query.address_lines.map { usps? ? usps_line(it) : clean(it) },
      administrative_area: usps? ? state(query.administrative_area) : clean(query.administrative_area),
      locality: clean(query.locality),
      organization: clean(query.organization),
      postal_code: usps? ? zip_code(query.postal_code) : clean(query.postal_code),
      region_code: query.region_code,
      sorting_code: clean(query.sorting_code),
      sublocality: clean(query.sublocality)
    )
  end

  def street_line
    line = clean(query.address_lines.first)
    return line if line.blank? || !usps?
    return line.sub(PO_BOX, 'PO BOX') if line.match?(PO_BOX)

    tokens = line.split
    street(tokens.first(unit_index(tokens))).join(' ')
  end

  private

  def clean(value) = value.to_s.upcase.gsub(APOSTROPHES, '').gsub(PUNCTUATION, ' ').gsub('#', ' # ').squish.presence
  def directionals = self.class.tables.fetch('directionals')
  def secondary_unit_designators = self.class.tables.fetch('secondary_unit_designators')
  def state(value) = clean(value).then { self.class.tables.fetch('states').fetch(it, it) if it.present? }

  def street(tokens)
    tokens = tokens.dup
    first = tokens.first.to_s.match?(/\A\d/) ? 1 : 0
    last = tokens.size - 1

    if last - first >= 2 && directionals.key?(tokens[last]) && street_suffixes.key?(tokens[last - 1])
      tokens[last] = directionals.fetch(tokens[last])
      last -= 1
    end

    tokens[last] = street_suffixes.fetch(tokens[last]) if last > first && street_suffixes.key?(tokens[last])
    tokens[first] = directionals.fetch(tokens[first]) if last - first >= 2 && directionals.key?(tokens[first])
    tokens
  end

  def street_end?(token) = street_suffixes.key?(token) || directionals.key?(token)
  def street_suffixes = self.class.tables.fetch('street_suffixes')
  def trailing_unit?(tokens, index) = index == tokens.size - 2 && tokens.last.match?(/\d/)

  def unit(tokens)
    designator, *rest = tokens
    return tokens if designator == '#'

    rest = rest.drop(1) if rest.first == '#'
    [secondary_unit_designators.fetch(designator), *rest]
  end

  def unit_index(tokens) = (1...tokens.size).find { unit_marker?(tokens, it) } || tokens.size

  def unit_marker?(tokens, index)
    return true if tokens[index] == '#'

    secondary_unit_designators.key?(tokens[index]) && (street_end?(tokens[index - 1]) || trailing_unit?(tokens, index))
  end

  def usps? = REGION_CODES.include?(query.region_code)

  def usps_line(value)
    line = clean(value)
    return if line.blank?
    return line.sub(PO_BOX, 'PO BOX') if line.match?(PO_BOX)

    tokens = line.split
    split = unit_index(tokens)

    [*street(tokens.first(split)), *(unit(tokens.drop(split)) if split < tokens.size)].join(' ')
  end

  def zip_code(value)
    match = clean(value)&.delete(' ')&.match(ZIP_CODE)
    return clean(value) if match.blank?

    [match[1], match[2]].compact.join('-')
  end
end
