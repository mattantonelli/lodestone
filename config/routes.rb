Rails.application.routes.draw do
  get 'static/index'

  root 'static#index'
end
