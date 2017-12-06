module Webhooks
  extend self

  CONFIG = OpenStruct.new(YAML.load_file('config/webhook.yml')).freeze
  AUTHORIZE_URL = 'https://discordapp.com/api/oauth2/authorize'.freeze
  TOKEN_URL = 'https://discordapp.com/api/oauth2/token'.freeze
  WEBHOOK_URL = 'https://discordapp.com/api/webhooks'.freeze

  def execute(category)
    name = category['name'].downcase
    new_posts = cache_posts(name, News.fetch(name, true))
    urls = Redis.current.smembers("#{name}-webhooks")

    return new_posts if new_posts.empty? || urls.empty?
    LodestoneLogger.info("Found #{new_posts.size} new posts for #{name.capitalize}")
    sent = removed = 0

    embeds = new_posts.map do |post|
      embed_post(post, category)
    end

    urls.each_slice(10) do |slice|
      threads = slice.map do |url|
        Thread.new do
          embeds.each do |embed|
            begin
              response = RestClient.post(url, { embeds: [embed] }.to_json, content_type: :json)
              sent += 1

              # Respect the dynamic rate limit
              if response.headers[:x_ratelimit_remaining] == '0'
                time = response.headers[:x_ratelimit_reset].to_i - Time.now.to_i
                sleep(time) if time.positive?
              end
            rescue RestClient::ExceptionWithResponse => e
              if JSON.parse(e.response)['code'] == 10015
                # Webhook has been deleted, so halt and remove it from Redis
                removed += 1 if Redis.current.srem("#{name}-webhooks", url)
              else
                LodestoneLogger.error("Failed to send \"#{embed[:title]}\" to #{url} - #{e.message}")
                LodestoneLogger.error(e.response.headers)
                LodestoneLogger.error(e.response.body)
              end
            end
          end
        end
      end

      # Wait for all threads to complete before continuing
      ThreadsWait.all_waits(*threads)
    end

    num_urls = urls.size - removed
    LodestoneLogger.info("#{removed} #{name.capitalize} webhooks unsubscribed.") if removed > 0
    LodestoneLogger.info("Sent #{sent}/#{new_posts.size * num_urls} updates " \
                "across #{num_urls} webhooks " \
                "subscribed to #{name.capitalize}.")
    new_posts
  end

  def execute_all
    News.categories.to_h.values.each do |category|
      execute(category)
      sleep(3) # A quick nap to ensure the rate limit buckets reset
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
