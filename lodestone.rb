require 'sinatra'
require 'sinatra/json'
require 'sinatra/custom_logger'
require 'sinatra/cross_origin'
require 'logger'

require 'open-uri'
require 'ostruct'
require 'time'
require 'thwait'
require 'tzinfo'
require 'yaml'
require 'securerandom'

configure do
  require_relative 'lib/logger.rb'
  require_relative 'lib/maintenance.rb'
  require_relative 'lib/news.rb'
  require_relative 'lib/scheduler.rb'
  require_relative 'lib/webhooks.rb'

  LOCALES = %w(na eu fr de jp).freeze
  HOSTS = YAML.load_file('config/hosts.yml').freeze
  GA_URL = 'www.google-analytics.com/collect'.freeze
  GA_TID = 'UA-109201715-1'.freeze

  use Rack::CommonLogger, LodestoneLogger.logger
  set :logger, LodestoneLogger.logger

  # Do not log requests to STDERR in production
  set :logging, nil if settings.production?

  # Cache static assets for one week
  set :static_cache_control, [:public, max_age: 604_800]

  # CORS
  set :allow_origin, :any
  set :allow_methods, [:get]

  Redis.current = Redis::Namespace.new(:lodestone)
  Scheduler.run
end

get '/' do
  @categories = { topics: '1', notices: '0', maintenance: '1', updates: '1', status: '0', developers: '1' }
  @state = @categories.values.join
  @code = params['code']
  @redirect_uri = "#{HOSTS[request_locale]}/authorize"
  erb :index
end

get '/authorize' do
  @state = params['state']
  redirect '/' if @state.nil? || params['error']

  @categories = News.categories.to_h.keys.map(&:to_s).zip(@state.chars).to_h
  @redirect_uri = "#{HOSTS[request_locale]}/authorize"

  begin
    url = Webhooks.url(params['code'], @redirect_uri)
    News.subscribe(@categories.merge('url' => url), request_locale)
    @flash = { success: 'You are now subscribed to Lodestone updates.' }
  rescue Exception => e
    logger.error "Failed to subscribe - #{e.message}"
    logger.error e.backtrace.join("\n") unless settings.production?
    @flash = { danger: 'Sorry, something went wrong. Please try again.' }
  end

  erb :index
end

get '/news/all' do
  track_request
  cross_origin
  news = News.all(request_locale)
  headers = NewsCache.headers(:topics, request_locale)
  last_modified headers[:last_modified]
  expires headers[:expires], :must_revalidate
  json news
end

get '/news/feed' do
  track_request
  cross_origin
  feed = News.feed(request_locale)
  headers = NewsCache.headers(:topics, request_locale)
  last_modified headers[:last_modified]
  expires headers[:expires], :must_revalidate
  json feed
end

get '/news/:category' do
  track_request
  cross_origin
  category = params[:category].downcase

  begin
    news = News.fetch(category, request_locale)
    headers = NewsCache.headers(category, request_locale)
    last_modified headers[:last_modified]
    expires headers[:expires], :must_revalidate
    json news
  rescue ArgumentError
    halt 400, json(error: 'Invalid news category.')
  end
end

get '/news/maintenance/current' do
  track_request

  unless %w(na eu).include?(request_locale)
    halt 500, json(error: 'Current maintenance is only supported for NA and EU.')
  end

  begin
    maintenance = News.current_maintenance(request_locale)
    headers = NewsCache.headers('maintenance', request_locale)
    last_modified headers[:last_modified]
    expires headers[:expires], :must_revalidate
    json maintenance
  end
end

# CORS preflight requests
options '*' do
  response.headers['Allow'] = 'GET,OPTIONS'
  response.headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept'
  200
end

not_found do
  erb 'errors/not_found'.to_sym
end

error do
  erb 'errors/error'.to_sym
end

def request_locale
  locale = request.host[0, 2]
  LOCALES.include?(locale) ? locale : 'na'
end

def track_request
  if settings.production?
    RestClient.post(GA_URL, { v: 1, tid: GA_TID, cid: Digest::MD5.hexdigest(request.ip),
                              t: 'pageview', dp: request.path.downcase })
  end
end
