Rails.application.routes.draw do
  get "pages/index"
  resources :workouts
  devise_for :users

  get '/payments/new', to: 'payments#new'
  get '/payments/success', to: 'payments#success'
  get '/payments/cancel', to: 'payments#cancel'
  post '/payments/create', to: 'payments#create'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "pages#index"
  
  post 'stripe/webhooks', to: 'stripe/webhooks#create'
  post 'stripe/checkout', to: 'stripe/checkout#checkout'
  get 'stripe/checkout/success', to: 'stripe/checkout#success'
  get 'stripe/checkout/cancel', to: 'stripe/checkout#cancel'
  post 'stripe/billing_portal', to: 'stripe/billing_portal#create'
  get '/upperbody', to: 'workouts#upperbody', as: 'upperbody'
  get '/lowerbody', to: 'workouts#lowerbody', as: 'lowerbody'
  get '/fullbody', to: 'workouts#fullbody', as: 'fullbody'
  get '/gluteships', to: 'workouts#gluteships', as: 'gluteships'
  get '/abscore', to: 'workouts#abscore', as: 'abscore'
end
