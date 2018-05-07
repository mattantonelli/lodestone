module Webhooks
  require_relative 'webhooks_resend.rb'

  extend self
  extend WebhooksResend

  CONFIG = OpenStruct.new(YAML.load_file('config/webhook.yml')).freeze
  AUTHORIZE_URL = 'https://discordapp.com/api/oauth2/authorize'.freeze
  TOKEN_URL = 'https://discordapp.com/api/oauth2/token'.freeze
  WEBHOOK_URL = 'https://discordapp.com/api/webhooks'.freeze

  def execute(type, category)
    name = category['name'].capitalize
    new_posts = cache_posts(type, News.fetch(type, true))
    urls = Redis.current.smembers("#{type}-webhooks")

    return new_posts if new_posts.empty? || urls.empty?
    LodestoneLogger.info("Found #{new_posts.size} new posts for #{name}.")
    sent = removed = failed = 0

    embeds = new_posts.map do |post|
      embed_post(post, category)
    end

    urls.each_slice(10) do |slice|
      threads = slice.map do |url|
        Thread.new do
          embeds.each do |embed|
            body = { embeds: [embed] }.to_json

            begin
              response = RestClient.post(url, body, content_type: :json)
              sent += 1

              # Respect the dynamic rate limit
              if response.headers[:x_ratelimit_remaining] == '0'
                time = response.headers[:x_ratelimit_reset].to_i - Time.now.to_i
                sleep(time) if time.positive?
              end
            rescue RestClient::ExceptionWithResponse => e
              if JSON.parse(e.response)['code'] == 10015
                # Webhook has been deleted, so halt and remove it from Redis
                removed += 1 if Redis.current.srem("#{type}-webhooks", url)
              else
                # Webhook failed to send, so add it to the resend queue to try again later
                failed += 1
                WebhooksResend.add(url, body)
              end
            end
          end
        end
      end

      # Wait for all threads to complete before continuing
      ThreadsWait.all_waits(*threads)
    end

    num_urls = urls.size - removed
    LodestoneLogger.info("#{removed} #{name} webhooks unsubscribed.") if removed > 0
    LodestoneLogger.info("#{failed} #{name} webhooks failed to send.") if failed > 0
    LodestoneLogger.info("Sent #{sent}/#{new_posts.size * num_urls} updates " \
                "across #{num_urls} webhooks " \
                "subscribed to #{name}.")
    new_posts
  end

  def execute_all
    News.categories.to_h.each do |type, category|
      execute(type.to_s, category)
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
