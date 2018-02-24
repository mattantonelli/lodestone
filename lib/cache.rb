module Cache
  extend self

  EXPIRES_IN = { news: 1800 }.freeze

  def cache(key, field, value)
    Redis.current.hset("#{key}-data", field, value.to_json)
    Redis.current.hset("#{key}-timestamps", field, Time.now)
  end

  def cached(key, field)
    JSON.parse(Redis.current.hget("#{key}-data", field), symbolize_names: true)
  end

  def headers(key, field)
    last_modified = Time.parse(Redis.current.hget("#{key}-timestamps", field))
    { last_modified: last_modified, expires: last_modified + EXPIRES_IN[key] }
  end

  def stale?(key, field)
    timestamp = Redis.current.hget("#{key}-timestamps", field)
    cache_time = timestamp ? Time.parse(timestamp) : Time.at(0)
    Time.now > cache_time + EXPIRES_IN[key]
  end
end

# Extension for easy generation of cache headers
module Sinatra
  module CacheHeaders
    def cache_headers(key, field)
      headers = Cache.headers(key, field)
      last_modified headers[:last_modified]
      expires headers[:expires], :must_revalidate
    end

    ::Sinatra.helpers CacheHeaders
  end
end
