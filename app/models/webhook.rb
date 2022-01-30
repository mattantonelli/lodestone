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

  def send_embed(embed)
    send_embeds([embed])
  end

  def send_embeds(embeds)
    begin
      body = { embeds: embeds }.to_json
      response = RestClient.post(url, body, content_type: :json)

      # Respect the dynamic rate limit
      if response.headers[:x_ratelimit_remaining] == '0'
        time = response.headers[:x_ratelimit_reset].to_i - Time.now.to_i
        sleep(time) if time.positive?
      end
    rescue RestClient::ExceptionWithResponse => e
      if JSON.parse(e.response)['code'] == 10015
        # Webhook has been deleted from the channel, so delete it from the database
        destroy
      else
        raise
      end
    end
  end

  def send_message(message)
    RestClient.post(url, { content: message })
  end
end
