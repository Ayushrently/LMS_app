Rails.application.routes.draw do
  get 'test/new'
  get 'test/edit'
  get 'test/throw'
  get 'test/clear'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "users#new"
  get "workspace", to: "courses#workspace"

  delete "logout", to: "users#logout", as: :logout

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

  resources :users, only: [:new, :create, :show] do
    resource :profile, only: [:show, :new, :create, :edit, :update]
  end

end
