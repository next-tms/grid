json.ignore_nil!

json.array!([@lookup]) do |lookup|
  json.input_id lookup.input_id.presence
  json.input_index 0

  if lookup.status.present?
    json.status lookup.status
    json.reason lookup.reason
  elsif lookup.result.smarty_zip_code
    json.merge!(lookup.result.smarty_zip_code.except(:input_id, :input_index))
  else
    result = lookup.result

    json.city_states [result] do
      json.city result.locality
      json.state_abbreviation result.administrative_area
      json.mailable_city true
    end

    json.zipcodes [result] do
      json.zipcode result.postal_code.first(5)
      json.default_city result.locality
      json.state_abbreviation result.administrative_area
      json.latitude result.geocode&.latitude&.to_f
      json.longitude result.geocode&.longitude&.to_f
      json.precision 'Zip5' if result.geocode.present?
    end
  end
end
