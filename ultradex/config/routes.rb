Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  # Route for the Turbo Frame content example
  get "home/turbo_frame_content", to: "home#turbo_frame_content", as: :home_turbo_frame_content
end
