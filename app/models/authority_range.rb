AuthorityRange = Data.define(:highest, :lowest) do
  class << self
    def of(authorities)
      ranked = authorities.compact.sort_by { Providers::Base::AUTHORITIES.index(it) }
      new(highest: ranked.first, lowest: ranked.last) if ranked.any?
    end

    def quality(authority) = (1 - Providers::Base::AUTHORITIES.index(authority).fdiv(Providers::Base::AUTHORITIES.size - 1)).round(3)
  end

  def quality = ((self.class.quality(highest) + self.class.quality(lowest)) / 2).round(3).clamp(0, 1)
end
