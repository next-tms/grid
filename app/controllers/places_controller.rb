class PlacesController < ApplicationController
  FIELDS = ['business_status', 'id', 'types'].freeze

  rescue_from ActiveRecord::RecordNotFound, with: :render_place_not_found

  def show
    return render_error(:bad_request, 'INVALID_ARGUMENT', 'FieldMask is a required parameter.') if field_mask.empty?

    @address = Address.from_place_id!(params.expect(:place_id))
    @fields = field_mask.include?('*') ? FIELDS : field_mask & FIELDS
    @validation = PlaceDetails.new(@address).call

    response.headers['Vary'] = 'X-Goog-FieldMask'
    fresh_until_expired([@validation].compact, @address, @fields)
  end

  private

  def field_mask = (request.headers['X-Goog-FieldMask'] || params[:fields]).to_s.split(',').map { it.strip.underscore }.compact_blank
  def render_place_not_found = render_error(:not_found, 'NOT_FOUND', "Place '#{params[:place_id]}' not found.")
end
