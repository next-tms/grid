class TimeZoneSearch
  attr_reader :name, :region_code

  def initialize(name: nil, region_code: nil)
    @name = name&.squish&.downcase.presence
    @region_code = region_code&.squish&.upcase.presence
  end

  def call = identifiers.select { matches?(it) }.sort.map { TimeZone.find(it) }

  private

  def abbreviation(identifier) = TZInfo::Timezone.get(identifier).current_period.abbreviation.downcase
  def labels(identifier) = [identifier.tr('_', ' '), *active_support_names.fetch(identifier, [])].map(&:downcase)
  def matches?(identifier) = name.nil? || abbreviation(identifier) == name || labels(identifier).any? { it.include?(name) }

  def active_support_names
    @active_support_names ||= ActiveSupport::TimeZone::MAPPING.group_by(&:last).transform_values { it.map(&:first) }
  end

  def identifiers
    return TZInfo::Timezone.all_data_zone_identifiers if region_code.blank?

    TZInfo::Country.get(region_code).zone_identifiers
  rescue TZInfo::InvalidCountryCode
    []
  end
end
