module NewsCache
  extend self

  EXPIRES_IN = 600.freeze # 10m

  def cache(news, type, locale)
    Redis.current.hset("#{locale}-news-data", type, news.to_json)
    Redis.current.hset("#{locale}-news-timestamps", type, Time.now)
  end

  def cached(type, locale)
    JSON.parse(Redis.current.hget("#{locale}-news-data", type), symbolize_names: true)
  end

  def headers(type, locale)
    last_modified = Time.parse(Redis.current.hget("#{locale}-news-timestamps", type))
    { last_modified: last_modified, expires: last_modified + EXPIRES_IN }
  end

  def stale?(type, locale)
    timestamp = Redis.current.hget("#{locale}-news-timestamps", type)
    cache_time = timestamp ? Time.parse(timestamp) : Time.at(0)
    Time.now > cache_time + EXPIRES_IN
  end
end
