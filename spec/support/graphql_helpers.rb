module GraphQLHelpers
  def execute(query, variables = {}) = JSONKeys.underscore(GridSchema.execute(query, context: { sources: }, variables:).to_h)
  def sources = @sources ||= []
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/graphql/}) { it[:type] = :graphql }
  config.include(GraphQLHelpers, type: :graphql)
end
