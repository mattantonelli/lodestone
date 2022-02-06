class LocaleController < ApplicationController
  def update
    locale = params[:locale]&.downcase
    locale = I18n.default_locale unless SUPPORTED_LOCALES.include?(locale)
    set_permanent_cookie(:locale, locale.downcase)
    redirect_to request.referer
  end
end
