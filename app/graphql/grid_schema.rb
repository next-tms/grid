class GridSchema < GraphQL::Schema
  class << self
    def id_from_object(object, _type_definition, _query_context) = object.to_gid_param
    def object_from_id(global_id, _query_context) = GlobalID.find(global_id)
    def resolve_type(_abstract_type, _object, _context) = raise(GraphQL::RequiredImplementationMissingError)
  end

  default_max_page_size(100)
  default_page_size(20)
  max_complexity(10_000)
  max_depth(15)

  validate_max_errors(100)

  query(Types::QueryType)

  use(GraphQL::Dataloader)
end
