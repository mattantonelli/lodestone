module WebhooksResend
  extend self

  def add(url, body)
    Redis.current.lpush('webhooks-resend', { url: url, body: body }.to_json)
  end

  def send_all
    redis = Redis.current
    count = redis.llen('webhooks-resend')
    return unless count > 0

    LodestoneLogger.info("Attempting to resend #{count} posts.")
    sent = 0

    while redis.llen('webhooks-resend') > 0
      webhook = JSON.parse(redis.lpop('webhooks-resend'), symbolize_names: true)

      begin
        response = RestClient.post(webhook[:url], webhook[:body], content_type: :json)
        sent += 1

        # Respect the dynamic rate limit
        if response.headers[:x_ratelimit_remaining] == '0'
          time = response.headers[:x_ratelimit_reset].to_i - Time.now.to_i
          sleep(time) if time.positive?
        end
      rescue RestClient::ExceptionWithResponse => e
        LodestoneLogger.error('Failed to resend post.')
        LodestoneLogger.error(e.response.headers)
        LodestoneLogger.error(e.response.body)
      end
    end

    LodestoneLogger.info("Re-sent #{sent}/#{count} posts successfully.")
  end
end
