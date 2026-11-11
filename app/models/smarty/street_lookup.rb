module Smarty
  class StreetLookup
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :addressee, :string
    attribute :city, :string
    attribute :input_id, :string
    attribute :lastline, :string
    attribute :match, :string
    attribute :secondary, :string
    attribute :state, :string
    attribute :street, :string
    attribute :street2, :string
    attribute :zipcode, :string

    validates :street, presence: true

    def candidates
      candidate = Candidate.new(lookup: self, result:)
      candidate.valid? || !strict? ? [candidate] : []
    end

    def query
      AddressQuery.new(
        address_lines: [street, secondary, street2, lastline],
        administrative_area: state,
        locality: city,
        organization: addressee,
        postal_code: zipcode,
        region_code: 'US'
      )
    end

    def result = @result ||= AddressValidator.new(query).call
    def strict? = ['enhanced', 'invalid'].exclude?(match)
  end
end
