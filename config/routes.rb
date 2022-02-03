Rails.application.routes.draw do
  resource :webhook, only: [] do
    post 'subscribe'
    get 'save'
  end

  # API
  resources :news, only: [], defaults: { format: :json } do
    collection do
      get 'topics'
      get 'notices'
      get 'maintenance'
      get 'updates'
      get 'status'
      get 'developers'

      get 'maintenance/current', action: 'current_maintenance'
      get 'feed'
      get 'all'
    end
  end

  match 'news/*path', via: :all, to: -> (_) { [404, { 'Content-Type' => 'application/json' },
                                              ['{"status": 404, "error": "Not found"}'] ] }

  root 'static#index'
end
