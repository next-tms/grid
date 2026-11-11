class GraphqlController < ApplicationController
  def execute
    variables = prepare_variables(params[:variables])

    render(json: GridSchema.execute(params[:query], operation_name: params[:operationName], variables:))
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  private

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
end
