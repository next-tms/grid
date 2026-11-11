class GraphqlController < ApplicationController
  def execute
    query = GraphQL::Query.new(GridSchema, params[:query], context: { sources: [] }, operation_name: params[:operationName],
                                                           variables: prepare_variables(params[:variables]))
    return render_mutation_not_allowed if request.get? && query.mutation?

    result = query.result
    fresh_until_expired(query.context[:sources]) if request.get? && cacheable?(result)
    render(json: result) unless performed?
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  private

  def cacheable?(result) = result['errors'].blank? && result['data'].present? && result['data'].values.all?

  def handle_error_in_development(exception)
    logger.error(exception.message)
    logger.error(exception.backtrace.join("\n"))

    render(json: { data: {}, errors: [{ backtrace: exception.backtrace, message: exception.message }] }, status: :internal_server_error)
  end

  def prepare_variables(variables_param)
    case variables_param
    when ActionController::Parameters then variables_param.to_unsafe_hash
    when Hash then variables_param
    when String then variables_param.present? ? JSON.parse(variables_param) || {} : {}
    when nil then {}
    else raise(ArgumentError, "Unexpected parameter: #{variables_param}")
    end
  end

  def render_mutation_not_allowed
    response.headers['Allow'] = 'POST'

    render(json: { errors: [{ message: 'Mutations require POST.' }] }, status: :method_not_allowed)
  end
end
