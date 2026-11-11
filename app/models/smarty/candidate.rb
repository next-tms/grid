module Smarty
  class Candidate
    DPV_MATCH_CODES = ['D', 'S', 'Y'].freeze
    PRECISIONS = { 'BLOCK' => 'Zip9', 'OTHER' => 'Zip5', 'PREMISE' => 'Rooftop', 'ROUTE' => 'Street' }.freeze

    attr_reader :lookup, :result

    delegate :address_lines, :administrative_area, :dpv_confirmation, :geocode, :locality, :smarty_street_address, to: :result
    delegate :input_id, to: :lookup

    def initialize(lookup:, result:)
      @lookup = lookup
      @result = result
    end

    def addressee = result.query.organization
    def delivery_line_1 = address_lines.first
    def delivery_line_2 = address_lines.second
    def last_line = [locality, administrative_area, result.postal_code].compact_blank.join(' ')
    def plus4_code = result.postal_code.to_s.split('-').second
    def precision = PRECISIONS.fetch(geocode&.geocode_granularity, 'Unknown')

    def rdi
      return 'Commercial' if result.business

      'Residential' if result.residential
    end

    def record_type = ('P' if result.po_box)
    def valid? = DPV_MATCH_CODES.include?(dpv_confirmation)
    def zipcode = result.postal_code.to_s.split('-').first
  end
end
