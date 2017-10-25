module NewsCache
  extend self

  EXPIRES_IN = 1800.freeze # 30m

  def cache(news, type)
    Redis.current.hset('news-data', type, news.to_json)
    Redis.current.hset('news-timestamps', type, Time.now)
  end

  def cached(type)
    JSON.parse(Redis.current.hget('news-data', type), symbolize_names: true)
  end

  def stale?(type)
    timestamp = Redis.current.hget('news-timestamps', type)
    cache_time = timestamp ? Time.parse(timestamp) : Time.at(0)
    Time.now > cache_time + EXPIRES_IN
  end
end
