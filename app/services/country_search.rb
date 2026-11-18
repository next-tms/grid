class CountrySearch
  attr_reader :name

  def initialize(name: nil)
    @name = name&.squish.presence
  end

  def call
    return ISO3166::Country.all if name.blank?

    Array(find_by_code || ISO3166::Country.find_country_by_any_name(name))
  end

  private

  def find_by_code = ISO3166::Country.all.find { [it.alpha2, it.alpha3].include?(name.upcase) }
end
