Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "users#new"

  delete "logout", to: "users#logout", as: :logout

  resources :courses do 
    resources :lessons, except: [:index] do
      resources :comments, only: [:create]
    end
    resources :comments, only: [:create]
    resources :enrollments, only: [:create, :destroy]
  end

  resources :users, only: [:new, :create, :show] do
    resource :profile, only: [:show, :new, :create, :edit, :update]
  end

end
