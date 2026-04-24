Rails.application.routes.draw do
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
    root to: "courses#index", as: :authenticated_root
  end

  devise_scope :user do
    root to: "devise/sessions#new"
  end
  get "workspace", to: "courses#workspace"

  resources :courses do 
    member do
      patch :update_authors
    end
    resources :lessons, except: [:index] do
      resources :comments, only: [:create, :edit, :update, :destroy]
    end
    resources :comments, only: [:create, :edit, :update, :destroy]
    resources :enrollments, only: [:create, :destroy]
  end

  resources :users, only: [:show] do
    resource :profile, only: [:show, :new, :create, :edit, :update]
  end

end
