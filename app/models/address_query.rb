class AddressQuery
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :address_lines, default: -> { [] }
  attribute :administrative_area, :string
  attribute :locality, :string
  attribute :organization, :string
  attribute :postal_code, :string
  attribute :region_code, :string
  attribute :sorting_code, :string
  attribute :sublocality, :string

  def address_lines=(value)
    super(Array(value).filter_map { it&.to_s&.squish.presence })
  end

  def region_code=(value)
    super(value&.to_s&.squish&.upcase.presence)
  end

  def key = [organization, to_s].compact_blank.join(', ').downcase
  def street? = address_lines.any?

  def to_s
    [*address_lines, sublocality, locality, [administrative_area, postal_code].compact_blank.join(' '),
     region_code].compact_blank.join(', ')
  end
end
