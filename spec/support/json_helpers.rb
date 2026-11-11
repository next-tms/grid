module JSONHelpers
  def json = JSONKeys.parse(response.body)
end

RSpec.configure { it.include(JSONHelpers, type: :request) }
