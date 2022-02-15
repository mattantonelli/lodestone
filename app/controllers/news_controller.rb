class NewsController < ApplicationController
  skip_before_action :set_locale # Do not set the locale cookie for API calls

  before_action :set_defaults
  before_action :set_headers
  before_action :render_news, only: [:topics, :notices, :maintenance, :updates, :status, :developers]

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
    @maintenance = { companion: [], game: [], lodestone: [], mog: [], psn: [] }
    @include_current = true

    news = News.where(locale: @locale)
      .where('end_time >= ?', Time.now)
      .where.not(start_time: nil)
      .order(created_at: :desc)

    news.each do |post|
      case post.title.downcase
      when /companion/ then @maintenance[:companion] << post
      when /world|data center/ then @maintenance[:game] << post
      when /lodestone/ then @maintenance[:lodestone] << post
      when /online store/ then @maintenance[:mog] << post
      when /psn/ then @maintenance[:psn] << post
      end
    end
  end

  def feed
    @news = News.where(locale: @locale).order(created_at: :desc).first(@limit)
    @include_category = true
    render 'basic'
  end

  def all
    @news = Lodestone.categories.each_with_object({}) do |category, h|
      h[category] = News.where(locale: @locale, category: category).order(created_at: :desc).first(@limit)
    end
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

  def set_headers
    meta = News.metadata(locale: @locale)
    expires_in(meta.max_age, must_revalidate: true, public: true)
    response.set_header('Last-Modified', meta.modified_at)
    response.set_header('Expires', meta.expires_at)
  end

  def render_news
    @news = News.where(locale: @locale, category: @category).order(created_at: :desc).first(@limit)
    render 'basic'
  end
end
