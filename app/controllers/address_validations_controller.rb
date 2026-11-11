class AddressValidationsController < ApplicationController
  ADDRESS_ATTRIBUTES = [:administrative_area, :locality, :organization, :postal_code, :region_code, :sorting_code, :sublocality,
                        { address_lines: [] }].freeze

  rescue_from ActionController::ParameterMissing, with: :render_missing_address
  rescue_from ActiveRecord::RecordNotFound, with: :render_unsupported_region_code

  def create
    @result = AddressValidator.new(AddressQuery.new(address_params)).call
  end

  private

  def address_params = params.deep_transform_keys(&:underscore).expect(address: ADDRESS_ATTRIBUTES)
  def render_missing_address = render_error(:bad_request, 'INVALID_ARGUMENT', 'address is required.')
  def render_unsupported_region_code = render_error(:bad_request, 'INVALID_ARGUMENT', 'Unsupported region code.')
end
