Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  root "home#index"

  get "/home", to: "home#index"

  get "/posts", to: "posts#index", as: :posts
  post "/posts", to: "posts#create"
  get "/posts/new", to: "posts#new", as: :new_post
  get "/posts/:id/edit", to: "posts#edit", as: :edit_post
  get "/posts/:id", to: "posts#show", as: :post
  patch "/posts/:id", to: "posts#update"
  put "/posts/:id", to: "posts#update"
  delete "/posts/:id", to: "posts#destroy"

  get "/reviews", to: "reviews#index", as: :reviews
  post "/reviews", to: "reviews#create"
  get "/reviews/new", to: "reviews#new", as: :new_review
  get "/reviews/:id/edit", to: "reviews#edit", as: :edit_review
  get "/reviews/:id", to: "reviews#show", as: :review
  patch "/reviews/:id", to: "reviews#update"
  put "/reviews/:id", to: "reviews#update"
  delete "/reviews/:id", to: "reviews#destroy"

  get "rss", to: "posts#rss", defaults: { format: :rss }
end
