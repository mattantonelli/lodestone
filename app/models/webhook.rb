# == Schema Information
#
# Table name: webhooks
#
#  id          :bigint(8)        not null, primary key
#  url         :string(255)      not null
#  locale      :string(255)      not null
#  topics      :boolean
#  notices     :boolean
#  maintenance :boolean
#  updates     :boolean
#  status      :boolean
#  developers  :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Webhook < ApplicationRecord
  validates_presence_of :url, :locale

  Lodestone.categories.each do |category|
    scope category, -> { where(category => true) }
  end

  Lodestone.locales.each do |locale|
    scope locale, -> { where(locale: locale) }
  end

  def send_embed(embed)
    send_embeds([embed])
  end

  def send_embeds(embeds)
    # Attempt to send the embeds up to 3 times to accommodate for sporadic Discord 5XX errors
    attempts = 0

    begin
      body = { embeds: embeds }.to_json
      response = RestClient.post(url, body, content_type: :json)

      # Respect the dynamic rate limit
      if response.headers[:x_ratelimit_remaining] == '0'
        sleep(response.headers[:x_ratelimit_reset_after].to_f)
      end
    rescue RestClient::ExceptionWithResponse => e
      if e.response.headers[:content_type] == 'application/json'
        # Check the Discord error code for valid JSON responses and handle appropriately
        response = JSON.parse(e.response)

        if response['code'] == 10015
          # Webhook has been deleted from the channel, so delete it from the database
          destroy
        else
          raise ArgumentError.new("Received an unhandled Discord error code: #{response['code']}")
        end
      else
        # Any response that isn't valid JSON is unparsable and should be retried
        if (attempts += 1) <= 3
          sleep(3)
          retry
        else
          raise ArgumentError.new('Discord server error.')
        end
      end
    end
  end

  def send_message(message)
    RestClient.post(url, { content: message })
  end
end
