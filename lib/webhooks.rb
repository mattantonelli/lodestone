module Webhooks
  extend self

  def execute(category)
    name = category['name'].downcase
    new_posts = cache_posts(name, News.fetch(name, true))
    urls = Redis.current.smembers("#{name}-webhooks")
    return new_posts if urls.empty?

    new_posts.each do |post|
      embed = embed_post(post, category)
      urls.each { |url| execute_webhook(url, embed) }
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

  def execute_webhook(url, embed)
    RestClient.post(url, { embeds: [embed] }.to_json, { content_type: :json })
    sleep(3) # Respect rate limit
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
