Rails.application.routes.draw do
  get 'up' => 'rails/health#show', as: :rails_health_check

  match '/graphql', to: 'graphql#execute', via: %i[get post]
  mount GraphiQL::Rails::Engine, at: '/graphiql', graphql_path: '/graphql'

  get '/maps/api/timezone/json', to: 'time_zones#show', defaults: { format: :json }
  get '/v1/places/:place_id', to: 'places#show', defaults: { format: :json }

  scope module: :smarty, defaults: { format: :json } do
    get '/lookup', to: 'zip_codes#show'
    get '/street-address', to: 'street_addresses#show'
  end

  post '/:rpc', to: 'address_validations#create', constraints: { rpc: 'v1:validateAddress' }, defaults: { format: :json }
end
