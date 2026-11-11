module Smarty
  class StreetAddressesController < ApplicationController
    def show
      @lookup = StreetLookup.new(params.permit(*StreetLookup.attribute_names))
      return head(:bad_request) if @lookup.invalid?

      @candidates = @lookup.candidates
      fresh_until_expired(@lookup.result.validations)
    end
  end
end
