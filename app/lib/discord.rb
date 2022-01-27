module Discord
  AUTHORIZE_URL = 'https://discord.com/api/oauth2/authorize'.freeze
  TOKEN_URL = 'https://discord.com/api/oauth2/token'.freeze
  WEBHOOK_URL = 'https://discord.com/api/webhooks'.freeze
  WEBHOOK_URL_FORMAT = /https:\/\/discord.com\/api\/webhooks\/\d+\/.+/.freeze

  extend self

  def authorize_url(state:, redirect_uri:)
    query = { response_type: 'code', scope: 'webhook.incoming', state: state, redirect_uri: redirect_uri,
              client_id: Rails.application.credentials.dig(:discord, :client_id) }

    uri = URI(Discord::AUTHORIZE_URL)
    uri.query = query.to_query
    uri.to_s
  end

  def webhook_url(code:, redirect_uri:)
    response = RestClient.post(TOKEN_URL,
                               { client_id: Rails.application.credentials.dig(:discord, :client_id),
                                 client_secret: Rails.application.credentials.dig(:discord, :client_secret),
                                 grant_type: 'authorization_code', code: code, redirect_uri: redirect_uri },
                                 { content_type: 'application/x-www-form-urlencoded' })

    webhook = JSON.parse(response, symbolize_names: true)[:webhook]
    url = "#{WEBHOOK_URL}/#{webhook[:id]}/#{webhook[:token]}"

    unless url.match?(WEBHOOK_URL_FORMAT)
      raise Exception.new("Invalid webhook URL: #{url}")
    end

    url
  end
end
