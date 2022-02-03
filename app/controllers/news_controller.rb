class NewsController < ApplicationController
  before_action :set_defaults
  before_action :set_news, only: [:topics, :notices, :maintenance, :updates, :status, :developers]

  def topics
  end

  def notices
  end

  def maintenance
  end

  def updates
  end

  def status
  end

  def developers
  end

  def current_maintenance
    # TODO: this
  end

  def feed
    # TODO: this
  end

  def all
    # TODO: this
  end

  private
  def set_defaults
    # Automatically set the news category based on the route
    @category = params[:action]

    # Ensure a valid locale has been provided, or default to NA
    @locale = params[:locale]&.downcase
    @locale = 'na' unless Lodestone.locales.include?(@locale)

    # The default and maximum values for the limit are 20
    @limit = params[:limit].to_i
    if @limit <= 0
      @limit = 20
    elsif @limit > 20
      @limit = 20
    end
  end

  def set_news
    @news = News.where(locale: @locale, category: @category).order(created_at: :desc).first(@limit)
  end
end
