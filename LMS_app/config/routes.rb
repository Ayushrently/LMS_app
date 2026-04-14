Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :courses do 
    resources :lessons, except: [:index]
    resources :enrollments, only: [:create, :destroy]
  end

  resources :users do
    resource :profile, only: [:show, :edit, :update]
  end

end
