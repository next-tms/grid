class TimeZonesController < ApplicationController
  def show
    location = Location.parse(params[:location])
    timestamp = Integer(params[:timestamp], exception: false)
    return render_status('INVALID_REQUEST', "Invalid request. Invalid 'location' parameter.") if location.blank?
    return render_status('INVALID_REQUEST', "Invalid request. Invalid 'timestamp' parameter.") if timestamp.blank?

    time_zone = TimeZoneLookup.new(location).call
    return render_status('ZERO_RESULTS') if time_zone.blank?

    @period = TZInfo::Timezone.get(time_zone.name).period_for(Time.zone.at(timestamp))
    @time_zone_name = time_zone.name
    fresh_until_expired([time_zone])
  rescue Providers::Error => e
    Sentry.capture_exception(e)
    render_status('UNKNOWN_ERROR', e.message)
  end

  private

  def render_status(status, error_message = nil)
    @error_message = error_message
    @status = status

    render(:status)
  end
end
