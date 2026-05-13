# frozen_string_literal: true

Rails.application.routes.draw do
  use_doorkeeper
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users
  get 'test/new'
  get 'test/edit'
  get 'test/throw'
  get 'test/clear'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  authenticated :user do
    root to: 'courses#index', as: :authenticated_root
  end

  devise_scope :user do
    root to: 'devise/sessions#new'
  end

  get 'workspace', to: 'courses#workspace'
  resources :courses do
    member do
      patch :update_authors
    end
    resources :lessons do
      resources :comments, only: %i[create edit update destroy]
    end
    resources :comments, only: %i[create edit update destroy]
    resources :enrollments, only: %i[create destroy]
  end

  resources :users, only: [:show] do
    resource :profile, only: %i[show new create edit update]
  end

  # API routes
  namespace :api do
    namespace :v1 do
      get 'workspace', to: 'courses#workspace'

      resources :courses, except: %i[new edit] do
        member do
          get :authors
          patch :add_authors
          patch :remove_authors
        end
        collection do
          get :search
        end
        resources :lessons, except: %i[new edit] do
          resources :comments, except: %i[new edit]
        end
        resources :comments, except: %i[new edit]
        resource :enrollment, only: %i[create destroy]
      end
      resources :users, only: [:show] do
        resource :profile, only: %i[show create update]
      end
    end
  end
end
