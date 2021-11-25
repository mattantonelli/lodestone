Rails.application.routes.draw do
  resource :webhook, only: [] do
    post 'subscribe'
    get 'save'
  end

  root 'static#index'
end
