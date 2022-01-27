class WebhooksController < ApplicationController
  def subscribe
    state = encode_options

    if state.match?('1')
      redirect_to Discord.authorize_url(state: encode_options, redirect_uri: save_webhook_url)
    else
      flash[:error] = I18n.t('subscribe.error.select_one')
      redirect_to root_path(locale: params[:locale])
    end
  end

  def save
    begin
      if params[:code].present?
        url = Discord.webhook_url(code: params[:code], redirect_uri: save_webhook_url)
        options = decode_options
        webhook = Webhook.create!(options[:categories].merge(url: url, locale: options[:locale]))
        webhook.send_message(I18n.t('subscribe.success.message'))
        flash[:success] = I18n.t('subscribe.success.flash')
      elsif params['error'] != 'access_denied'
        # If the OAuth response is missing the code and was not cancelled by the user, raise an error
        Rails.logger.error('Discord did not return a code:')
        Rails.logger.error(params)
        flash[:error] = I18n.t('subscribe.error.unknown')
      end
    rescue Exception => e
      Rails.logger.error(e.inspect)
      flash[:error] = I18n.t('subscribe.error.unknown')
    end

    redirect_to root_path
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
