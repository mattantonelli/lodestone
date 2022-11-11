Rails.application.routes.draw do
  get 'locale/set', to: 'locale#update'

  resource :feed, only: [], defaults: { format: :xml } do
    Lodestone.locales.each do |locale|
      get locale
    end
  end

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

      get 'post/:id', action: 'post', as: :post
      get 'maintenance/current', action: 'current_maintenance'
      get 'feed'
      get 'all'
    end
  end

  get 'docs', to: redirect('https://documenter.getpostman.com/view/1779678/TzXzDHVk')

  # 404 for unknown API routes
  match 'news/*path', via: :all, to: -> (_) { [404, { 'Content-Type' => 'application/json' },
                                              ['{"status": 404, "error": "Not found"}'] ] }

  # 404 for all other unknown routes
  match '*path', via: :all, to: redirect('/')

  root 'static#index'
end
