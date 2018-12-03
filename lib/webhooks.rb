module Webhooks
  require_relative 'webhooks_resend.rb'

  extend self
  extend WebhooksResend

  CONFIG = OpenStruct.new(YAML.load_file('config/webhook.yml')).freeze
  AUTHORIZE_URL = 'https://discordapp.com/api/oauth2/authorize'.freeze
  TOKEN_URL = 'https://discordapp.com/api/oauth2/token'.freeze
  WEBHOOK_URL = 'https://discordapp.com/api/webhooks'.freeze

  def execute(type, category, locale)
    name = category['name'].capitalize
    new_posts = cache_posts(type, locale, News.fetch(type, locale, true))
    urls = Redis.current.smembers("#{locale}-#{type}-webhooks")

    return new_posts if new_posts.empty? || urls.empty?
    LodestoneLogger.info("Found #{new_posts.size} new posts for #{locale.upcase} #{name}.")
    sent = removed = failed = 0

    embeds = new_posts.map do |post|
      embed_post(post, category, locale)
    end

    embeds.each do |embed|
      body = { embeds: [embed] }.to_json
      urls.each_slice(20) do |slice|
        threads = slice.map do |url|
          Thread.new do
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
                removed += 1 if Redis.current.srem("#{locale}-#{type}-webhooks", url)
              else
                LodestoneLogger.error(e.inspect)
                WebhooksResend.add(url, body)
                failed += 1
              end
            rescue Exception => e
              LodestoneLogger.error(e.inspect)
              e.backtrace.each { |line| LodestoneLogger.error(line) }
              WebhooksResend.add(url, body)
              failed += 1
            end
          end
        end

        ThreadsWait.all_waits(*threads)
      end
    end

    num_urls = urls.size - removed
    LodestoneLogger.info("#{removed} #{locale.upcase} #{name} webhooks unsubscribed.") if removed > 0
    LodestoneLogger.info("#{failed} #{locale.upcase} #{name} webhooks failed to send.") if failed > 0
    LodestoneLogger.info("Sent #{sent}/#{new_posts.size * num_urls} updates " \
                         "across #{num_urls} webhooks " \
                         "subscribed to #{locale.upcase} #{name}.")
    new_posts
  end

  def execute_all
    threads = LOCALES.map do |locale|
      Thread.new do
        News.categories.to_h.each do |type, category|
          execute(type.to_s, category, locale)
          sleep(3) # A quick nap to ensure the rate limit buckets reset
        end
      end
    end

    ThreadsWait.all_waits(*threads)
  end

  # Create a webhook URL using an OAuth code
  def url(code, redirect_uri)
    response = RestClient.post(TOKEN_URL,
                               { client_id: CONFIG.client_id, client_secret: CONFIG.client_secret,
                                 grant_type: 'authorization_code', code: code, redirect_uri: redirect_uri },
                               { content_type: 'application/x-www-form-urlencoded' })

    webhook = JSON.parse(response, symbolize_names: true)[:webhook]
    "#{WEBHOOK_URL}/#{webhook[:id]}/#{webhook[:token]}"
  end

  def send_message(url, message)
    RestClient.post(url, { content: message })
  end

  def send_announcement(message)
    body = { content: message }.to_json
    count = 0
    urls = Redis.current.smembers('all-webhooks')

    urls.each_slice(20) do |slice|
      threads = slice.map do |url|
        Thread.new do
          begin
            RestClient.post(url, body, content_type: :json)
            count += 1
          rescue RestClient::ExceptionWithResponse => e
            if JSON.parse(e.response)['code'] == 10015
              Redis.current.srem('all-webhooks', url)
            end
          end
        end
      end

      ThreadsWait.all_waits(*threads)
    end

    LodestoneLogger.info("Sent announcement to #{count} webhooks.")
  end

  private
  # Cache any new post IDs for the given category and return the new posts
  def cache_posts(name, locale, posts)
    posts.select { |post| Redis.current.sadd("#{locale}-#{name}-ids", post[:id]) }
  end

  def embed_post(post, category, locale)
    link = URI.parse(category['link'])
    link.host = "#{locale}.#{link.host}"

    {
      author: {
        name: category['name'],
        url: link,
        icon_url: category['icon']
      },
      title: post[:title],
      description: post[:description],
      url: post[:url],
      color: category['color'],
      thumbnail: {
        url: category['thumbnail']
      },
      image: {
        url: post[:image]
      }
    }
  end
end
