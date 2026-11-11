json.ignore_nil!

json.array!(@candidates) do |candidate|
  if candidate.smarty_street_address.present?
    json.merge!(candidate.smarty_street_address.merge(candidate_index: 0, input_id: candidate.input_id.presence, input_index: 0).compact)
  else
    json.input_id candidate.input_id.presence
    json.input_index 0
    json.candidate_index 0
    json.addressee candidate.addressee
    json.delivery_line_1 candidate.delivery_line_1
    json.delivery_line_2 candidate.delivery_line_2
    json.last_line candidate.last_line

    json.components do
      json.city_name candidate.locality
      json.state_abbreviation candidate.administrative_area
      json.zipcode candidate.zipcode
      json.plus4_code candidate.plus4_code
    end

    json.metadata do
      json.record_type candidate.record_type
      json.rdi candidate.rdi
      json.latitude candidate.geocode&.latitude&.to_f
      json.longitude candidate.geocode&.longitude&.to_f
      json.precision candidate.precision
    end

    json.analysis { json.dpv_match_code candidate.dpv_confirmation }
  end
end
