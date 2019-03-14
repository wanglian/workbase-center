Rails.application.routes.draw do
  mount Base => '/'
  mount GrapeSwaggerRails::Engine => '/api_doc'

  devise_for :admins

  resources :instances

  root "home#index"
end
