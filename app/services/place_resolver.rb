class PlaceResolver
  attr_reader :provider, :records

  def initialize(provider, records)
    @provider = provider
    @records = records.to_a
  end

  def call = records.map { resolve(it) }

  private

  def resolve(record)
    place = provider.place(record)
    stored = stored_places[record.id]
    place.assign_attributes(address: stored.address, id: stored.id) if stored.present?
    place
  end

  def stored_places
    @stored_places ||= Place.identified_by(provider: provider.key, value: records.map(&:id))
                            .includes(:provider_identifiers, address: %i[administrative_area country locality postal_code])
                            .index_by { |place| place.provider_identifiers.find { it.provider == provider.key }.value }
  end
end
