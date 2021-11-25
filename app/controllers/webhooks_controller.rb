class WebhooksController < ApplicationController
  def subscribe
    state = encode_options

    if state.match?('1')
      redirect_to Discord.authorize_url(state: encode_options, redirect_uri: save_webhook_url)
    else
      flash[:error] = 'You must select at least one category.'
      redirect_to root_path(locale: params[:locale])
    end
  end

  def save
    begin
      url = Discord.webhook_url(code: params[:code], redirect_uri: save_webhook_url)
      options = decode_options
      Webhook.create!(options[:categories].merge(url: url, locale: options[:locale]))
      flash[:success] = 'You are now subscribed to Lodestone News updates.'
      redirect_to root_path
    rescue Exception => e
      Rails.logger.error(e.inspect)
      flash[:error] = 'Sorry, there was a problem with your subscription.'
      redirect_to root_path(options: options)
    end
  end

  private
  def encode_options
    categories = Lodestone::CATEGORIES.to_h.keys.map do |category|
      params[category] ? '1' : '0'
    end

    "#{categories.join}#{params[:locale]}"
  end

  def decode_options
    categories = Lodestone::CATEGORIES.to_h.keys.each_with_index.map do |category, i|
      [category, params[:state][i]]
    end

    { categories: categories.to_h, locale: params[:state][-2..-1] }
  end
end
