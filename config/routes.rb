Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Distance calculation routes
  get "distance", to: "distance#index"
  post "distance/calculate", to: "distance#calculate"
  
  # API endpoint for JSON requests
  namespace :api do
    namespace :v1 do
      post "distance", to: "distance#calculate"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions
  get "up" => "rails/health#show", as: :rails_health_check

  # Root route
  root "distance#index"
end
