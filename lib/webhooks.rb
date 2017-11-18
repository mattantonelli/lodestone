module Webhooks
  extend self

  CONFIG = OpenStruct.new(YAML.load_file('config/webhook.yml')).freeze
  AUTHORIZE_URL = 'https://discordapp.com/api/oauth2/authorize'.freeze
  TOKEN_URL = 'https://discordapp.com/api/oauth2/token'.freeze
  WEBHOOK_URL = 'https://discordapp.com/api/webhooks'.freeze

  def execute(category, logger)
    name = category['name'].downcase
    new_posts = cache_posts(name, News.fetch(name, true))
    urls = Redis.current.smembers("#{name}-webhooks")

    return new_posts if new_posts.empty? || urls.empty?
    logger.info("Found #{new_posts.size} new posts for #{name.capitalize}")
    sent, num_posts = 0, new_posts.size

    embeds = new_posts.map do |post|
      embed_post(post, category)
    end

    urls.each_slice(10) do |slice|
      threads = slice.map do |url|
        Thread.new do
          embeds.each do |embed|
            begin
              RestClient.post(url, { embeds: [embed] }.to_json, { content_type: :json })
              sent += 1
              sleep(3) if num_posts > 1 # Respect rate limit
            rescue RestClient::ExceptionWithResponse => e
              # Webhook has been deleted, so halt and remove it from Redis
              if JSON.parse(e.response)['code'] == 10015
                Redis.current.srem("#{name}-webhooks", url)
                logger.info("Removing deleted webhook #{url}")
                break
              else
                logger.error("Failed to send \"#{embed[:title]}\" to #{url}")
              end
            end
          end
        end
      end

      # Wait for all threads to complete before continuing
      ThreadsWait.all_waits(*threads)
    end

    logger.info("Sent #{sent}/#{num_posts * urls.size} updates " \
                "across #{urls.size} webhooks " \
                "subscribed to #{name.capitalize}.")
    new_posts
  end

  def execute_all(logger)
    News.categories.to_h.values.each do |category|
      execute(category, logger)
    end
  end

  # Create a webhook URL using an OAuth code
  def url(code)
    response = RestClient.post(TOKEN_URL,
                               { client_id: CONFIG.client_id, client_secret: CONFIG.client_secret,
                                 grant_type: 'authorization_code', code: code, redirect_uri: CONFIG.redirect_uri },
                               { content_type: 'application/x-www-form-urlencoded' })

    webhook = JSON.parse(response, symbolize_names: true)[:webhook]
    "#{WEBHOOK_URL}/#{webhook[:id]}/#{webhook[:token]}"
  end

  def send_message(url, message)
    RestClient.post(url, { content: message })
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
