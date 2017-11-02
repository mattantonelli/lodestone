require 'sinatra'
require 'sinatra/json'

require 'open-uri'
require 'ostruct'
require 'time'
require 'yaml'

Dir['lib/*.rb'].each { |file| load file }

Redis.current = Redis::Namespace.new(:lodestone)

Scheduler.run

get '/' do
  @categories = { topics: '1', notices: '0', maintenance: '1', updates: '1', status: '0' }
  erb :index
end

post '/' do
  @url = params['url']
  @flash = { success: 'Subscription updated successfully.' }
  @categories = News.categories.to_h.keys.each_with_object({}) do |category, h|
    h[category.to_s] = params.dig('categories', category) || '0'
  end

  News.subscribe(@categories.merge('url' => @url))

  erb :index
end

get '/news/subscribe' do
  cache_control :no_cache

  begin
    json News.subscribe(params)
  rescue ArgumentError
    halt 400, json(error: 'Invalid webhook URL.')
  end
end

get '/news/:category' do
  category = params[:category].downcase

  begin
    news = News.fetch(category)
    headers = NewsCache.headers(category)
    last_modified headers[:last_modified]
    expires headers[:expires], :must_revalidate
    json news
  rescue ArgumentError
    halt 400, json(error: 'Invalid news category.')
  end
end

not_found do
  json(error: 'Resource not found.')
end

error do
  json(error: 'Could not retrieve Lodestone data.')
end
