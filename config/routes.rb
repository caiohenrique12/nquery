# frozen_string_literal: true

Nquery::Engine.routes.draw do
  root to: "home#index"

  get "browse", to: redirect("/collections")

  namespace :onboarding do
    resource :company, only: %i[new create], controller: "companies"
    resource :admin, only: %i[new create], controller: "admins"
    get "congrats", to: "congrats#show"
    get "confirm", to: "confirmations#show", as: :confirm
    patch "confirm", to: "confirmations#update"
  end

  resources :collections do
    member do
      patch :archive
      patch :unarchive
    end

    resources :collections, only: %i[new create]
    resources :dashboards, only: %i[new create], module: :collection
  end

  resources :queries, only: %i[new create edit update show] do
    post :run, on: :collection
    get :schema, on: :collection
  end

  resources :charts, only: %i[new create show edit update destroy] do
    member do
      get :embed
      patch :archive
    end
  end

  resources :dashboards, except: %i[new create] do
    resources :charts, module: :dashboard do
      member do
        get :embed
        patch :archive
      end
    end

    member do
      patch :update_layout
      patch :archive
      patch :unarchive
    end
  end

  resources :imports, only: %i[new create]

  namespace :admin do
    resources :users, only: %i[index show new create edit update destroy] do
      member do
        patch :deactivate
      end
    end
    resources :groups, only: %i[index show new create edit update] do
      post :add_member, on: :member
      delete :remove_member, on: :member
    end
    resources :data_sources, only: %i[index new create edit update]
    resources :logs, only: %i[index]
    resources :permissions, only: %i[index] do
      collection do
        get :by_group
        get :by_data_source
        get :by_collection
      end
    end
  end

  devise_for :nquery_users,
             class_name: "Nquery::User",
             path: "",
             path_names: { sign_in: "login", sign_out: "logout" },
             controllers: { sessions: "nquery/sessions" },
             router_name: :nquery,
             sign_out_via: :delete,
             skip: %i[registrations passwords confirmations unlocks]

  devise_scope :nquery_user do
    get "users/confirmation", to: "onboarding/confirmations#show", as: :nquery_user_confirmation
  end

  namespace :embed do
    get "charts/show", to: "charts#show", as: :public_chart
    get "dashboards/show", to: "dashboards#show", as: :public_dashboard
  end

  match "*unmatched", to: "errors#not_found", via: :all
end
