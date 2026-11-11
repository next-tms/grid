module Smarty
  class ZIPCodesController < ApplicationController
    def show
      @lookup = ZIPCodeLookup.new(params.permit(*ZIPCodeLookup.attribute_names))
      fresh_until_expired(@lookup.result.validations) if @lookup.status.blank?
    end
  end
end
