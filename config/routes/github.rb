namespace :github, defaults: { format: :json } do
	resources :callbacks

end

get '/auth/:provider/callback', :to => 'user_sessions#create'
get '/auth/failure', :to => 'user_sessions#failure'
