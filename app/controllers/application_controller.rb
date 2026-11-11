class ApplicationController < ActionController::API
  private

  def fresh_until_expired(sources, *etag)
    return if sources.empty?
    return no_store unless sources.all?(&:stores_content?)

    expires_in([sources.map(&:expires_at).min - Time.current, 0].max, public: true)
    fresh_when(etag: [*sources, *etag], last_modified: sources.map(&:fetched_at).max)
  end

  def render_error(status, code, message)
    @error = { code: Rack::Utils.status_code(status), message:, status: code }

    render('errors/show', status:)
  end
end
