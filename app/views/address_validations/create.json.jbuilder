json.key_format!(JSONKeys::LOWER_CAMEL_CASE)

json.result do
  json.verdict do
    json.input_granularity @result.input_granularity
    json.validation_granularity @result.validation_granularity
    json.geocode_granularity @result.geocode_granularity
    json.address_complete true if @result.address_complete?
    json.has_unconfirmed_components true if @result.unconfirmed_components?
    json.has_inferred_components true if @result.inferred_components?
    json.has_replaced_components true if @result.replaced_components?
  end

  json.address do
    json.formatted_address @result.formatted_address
    json.postal_address do
      json.region_code @result.region_code
      json.language_code 'en'
      json.postal_code @result.postal_code if @result.postal_code.present?
      json.administrative_area @result.administrative_area if @result.administrative_area.present?
      json.locality @result.locality if @result.locality.present?
      json.address_lines @result.address_lines
      json.organization @result.query.organization if @result.query.organization.present?
    end
  end

  json.geocode do
    if @result.geocode.present?
      json.location do
        json.latitude @result.geocode.latitude.to_f
        json.longitude @result.geocode.longitude.to_f
      end
      json.plus_code { json.global_code @result.location.plus_code }
    end
    json.place_id @result.place_id
  end

  json.metadata do
    json.business @result.business unless @result.business.nil?
    json.po_box @result.po_box unless @result.po_box.nil?
    json.residential @result.residential unless @result.residential.nil?
  end

  street_address = @result.smarty_street_address

  if street_address.present?
    json.usps_data do
      json.standardized_address do
        json.first_address_line street_address[:delivery_line_1]
        json.city_state_zip_address_line street_address[:last_line]
        json.city street_address.dig(:components, :city_name)
        json.state street_address.dig(:components, :state_abbreviation)
        json.zip_code street_address.dig(:components, :zipcode)
        json.zip_code_extension street_address.dig(:components, :plus4_code)
      end
      json.dpv_confirmation street_address.dig(:analysis, :dpv_match_code)
      json.dpv_footnote street_address.dig(:analysis, :dpv_footnotes)
      json.dpv_cmra street_address.dig(:analysis, :dpv_cmra)
      json.dpv_vacant street_address.dig(:analysis, :dpv_vacant)
      json.dpv_no_stat street_address.dig(:analysis, :dpv_no_stat)
      json.carrier_route street_address.dig(:metadata, :carrier_route)
      json.county street_address.dig(:metadata, :county_name)
      json.fips_county_code street_address.dig(:metadata, :county_fips)
    end
  end
end

json.response_id SecureRandom.uuid
