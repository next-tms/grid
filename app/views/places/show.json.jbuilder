json.key_format!(JSONKeys::LOWER_CAMEL_CASE)

json.id @address.place_id if @fields.include?('id')

if @validation.present?
  json.types @validation.types if @fields.include?('types') && @validation.types.any?

  unless @validation.permanently_closed.nil? || @fields.exclude?('business_status')
    json.business_status(@validation.permanently_closed ? 'CLOSED_PERMANENTLY' : 'OPERATIONAL')
  end
end
