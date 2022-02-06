class ApplicationController < ActionController::Base
  before_action :set_locale

  SUPPORTED_LOCALES = %w(en de fr).freeze

  def set_permanent_cookie(key, value)
    cookies[key] = { value: value, expires: 20.years.from_now, same_site: :lax }
  end

  private
  def set_locale
    locale = cookies[:locale]

    unless locale.present?
      locale = request.env['HTTP_ACCEPT_LANGUAGE']&.scan(/^[a-z]{2}/)&.first&.downcase

      unless locale.present? && SUPPORTED_LOCALES.include?(locale)
        locale = I18n.default_locale
      end

      set_permanent_cookie(:locale, locale)
    end

    I18n.locale = cookies[:locale]
  end

end
