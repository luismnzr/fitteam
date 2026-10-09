Rails.application.routes.draw do
  devise_for :users

  # Admin (solo usuarias con admin = true; ver Admin::BaseController). Toda la
  # escritura de contenido vive aquí: el sitio público es de solo lectura.
  namespace :admin do
    root to: "dashboard#show"

    resources :workouts, except: [ :show ]
    get "calendario", to: "calendar#show", as: :calendar

    resources :users, only: [ :index, :show, :edit, :update ] do
      post :send_password_reset, on: :member
      post :sync_stripe, on: :member
    end

    resources :comments, only: [ :index, :destroy ] do
      post :reply, on: :member
    end
  end

  resources :workouts, only: [ :index, :show ] do
    resources :comments, only: [ :create ]
  end
  get "workouts/:id/thumbnail/:size", to: "workout_thumbnails#show", as: :workout_thumbnail,
                                       constraints: { size: /card|cover/ }, format: false

  resources :favorite_workouts, only: [ :create, :destroy ]
  get "/favorites", to: "workouts#favorites", as: "favorites"

  get "/payments/new", to: "payments#new"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "pages#index"

  post "stripe/webhooks", to: "stripe/webhooks#create"
  post "stripe/checkout", to: "stripe/checkout#checkout"
  get "stripe/checkout/success", to: "stripe/checkout#success"
  get "stripe/checkout/cancel", to: "stripe/checkout#cancel"
  post "stripe/billing_portal", to: "stripe/billing_portal#create"
  get "/upperbody", to: "workouts#upperbody", as: "upperbody"
  get "/lowerbody", to: "workouts#lowerbody", as: "lowerbody"
  get "/fullbody", to: "workouts#fullbody", as: "fullbody"
  get "/gluteships", to: "workouts#gluteships", as: "gluteships"
  get "/abscore", to: "workouts#abscore", as: "abscore"
  get "/short_1530", to: "workouts#short_1530", as: "short_1530"
  get "/strength", to: "workouts#strength", as: "strength"
  get "/all", to: "workouts#all", as: "all"
  get "/calendario", to: "workouts#calendario", as: "calendario"

  get "/pages/acerca", to: "pages#acerca", as: "acerca"
  get "/pages/preguntasfrecuentes", to: "pages#preguntasfrecuentes", as: "preguntasfrecuentes"
  get "/pages/terminos", to: "pages#terminos", as: "terminos"
end
