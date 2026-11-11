json.key_format!(JSONKeys::LOWER_CAMEL_CASE)

json.dst_offset @period.std_offset
json.raw_offset @period.base_utc_offset
json.status 'OK'
json.time_zone_id @time_zone_name
json.time_zone_name @period.abbreviation
