module Smarty
  class ZIPCodeLookup
    include ActiveModel::Model
    include ActiveModel::Attributes

    FORMAT = /\A\d{5}(-?\d{4})?\z/
    REASONS = {
      'blank' => 'Blank lookup (you must provide a ZIP Code and/or City/State combination).',
      'invalid_zipcode' => 'Invalid ZIP Code.'
    }.freeze

    attribute :input_id, :string
    attribute :zipcode, :string

    def zipcode=(value)
      super(value&.to_s&.strip.presence)
    end

    def query = AddressQuery.new(postal_code: zipcode.first(5), region_code: 'US')
    def reason = REASONS[status]
    def result = @result ||= AddressValidator.new(query).call

    def status
      return 'blank' if zipcode.blank?

      'invalid_zipcode' unless zipcode.match?(FORMAT) && result.validation&.locality.present?
    end
  end
end
