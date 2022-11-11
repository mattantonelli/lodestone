class FeedsController < ApplicationController
  before_action :set_headers, :check_freshness, :render_feed

  def na
  end

  def eu
  end

  def fr
  end

  def de
  end

  def jp
  end

  private
  def set_headers
    @meta = News.metadata(locale: action_name)
    expires_in(@meta.max_age, must_revalidate: true, public: true)
    response.set_header('Last-Modified', @meta.modified_at)
    response.set_header('Expires', @meta.expires_at)
  end

  def check_freshness
    fresh_when(last_modified: @meta.modified_at)
  end

  def render_feed
    @news = News.where(locale: action_name).ordered.first(20)
    render 'feed'
  end
end
