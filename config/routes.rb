# frozen_string_literal: true

Nquery::Engine.routes.draw do
  root to: "home#index"

  get "browse", to: "browse#index"

  resources :queries, only: %i[new create edit update show] do
    post :run, on: :collection
    get :schema, on: :collection
  end

  resources :charts, only: %i[show edit update] do
    member do
      get :embed
    end
  end

  resources :dashboards, only: %i[show edit update] do
    member do
      patch :update_layout
    end
  end

  resources :imports, only: %i[new create]

  namespace :admin do
    resources :users, only: %i[index show new create edit update]
    resources :groups, only: %i[index show new create edit update] do
      post :add_member, on: :member
      delete :remove_member, on: :member
    end
    resources :data_sources, only: %i[index new create edit update]
    resources :permissions, only: %i[index] do
      collection do
        get :by_group
        get :by_data_source
        get :by_collection
      end
    end
  end

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  namespace :embed do
    get "charts/:token", to: "charts#show", as: :public_chart
    get "dashboards/:token", to: "dashboards#show", as: :public_dashboard
  end
end
