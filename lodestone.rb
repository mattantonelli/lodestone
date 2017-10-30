require 'sinatra'
require 'sinatra/json'

require 'open-uri'
require 'ostruct'
require 'time'
require 'yaml'

Dir['lib/*.rb'].each { |file| load file }

disable :show_exceptions

Redis.current = Redis::Namespace.new(:lodestone)

Scheduler.run

get '/news/subscribe' do
  cache_control :no_cache

  categories = News.categories.to_h.keys.map(&:to_s)

  subscriptions = categories.each_with_object({}) do |category, h|
    choice = params[category]

    if choice == '1'
      Redis.current.sadd("#{category}-webhooks", params['url'])
      h[category] = true
    elsif choice == '0'
      Redis.current.srem("#{category}-webhooks", params['url'])
      h[category] = false
    end
  end

  json(subscriptions: subscriptions)
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
