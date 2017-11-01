module Webhooks
  extend self

  def execute(category)
    name = category['name'].downcase
    new_posts = cache_posts(name, News.fetch(name, true))
    urls = Redis.current.smembers("#{name}-webhooks")
    return new_posts if urls.empty?

    embeds = new_posts.map do |post|
      embed_post(post, category)
    end

    urls.each do |url|
      Thread.new do
        embeds.each do |embed|
          begin
            RestClient.post(url, { embeds: [embed] }.to_json, { content_type: :json })
            sleep(1) # Respect rate limit
          rescue RestClient::ExceptionWithResponse => e
            # Webhook has been deleted, so halt and remove it from Redis
            if JSON.parse(e.response)['code'] == 10015
              Redis.current.srem("#{name}-webhooks", url)
              break
            end
          end
        end
      end
    end
  end

  def execute_all
    News.categories.to_h.values.each do |category|
      execute(category)
    end
  end

  private
  # Cache any new post IDs for the given category and return the new posts
  def cache_posts(name, posts)
    posts.select { |post| Redis.current.sadd("#{name}-ids", post[:id]) }
  end

  def embed_post(post, category)
    {
      author: {
        name: category['name'],
        url: category['url'],
        icon_url: category['icon']
      },
      title: post[:title],
      description: post[:description],
      url: post[:url],
      color: category['color'],
      timestamp: post[:time],
      thumbnail: {
        url: category['thumbnail']
      },
      image: {
        url: post[:image]
      }
    }
  end
end
