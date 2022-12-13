require 'net/http'

module Lodestone
  include Lodestone::Maintenance

  BASE_URL = 'https://finalfantasyxiv.com'.freeze
  LODESTONE_URL = 'https://finalfantasyxiv.com/lodestone'.freeze
  DEVELOPERS_URL = 'https://finalfantasyxiv.com/blog/atom.xml'.freeze
  CATEGORIES = YAML.load_file('config/categories.yml').freeze
  LOCALES = %w(na eu fr de jp).freeze

  extend self

  def fetch_news(locale:)
    uri = URI.parse(LODESTONE_URL)
    uri.host = "#{locale}.#{uri.host}"

    page = Nokogiri::HTML(Net::HTTP.get_response(uri).body)
    news = parse_news(page, locale) + parse_topics(page, locale)

    create_posts(locale: locale, news: news)
  end

  def fetch_blog(locale:)
    uri = URI.parse(DEVELOPERS_URL)
    uri.host = "#{locale}.#{uri.host}"

    page = Nokogiri::HTML(Net::HTTP.get_response(uri).body)
    news = parse_blog(page, locale)

    create_posts(locale: locale, news: news)
  end

  def fetch_all(locale:)
    fetch_news(locale: locale)
    fetch_blog(locale: locale)
  end

  def fetch_category(category:, locale:, page: 1)
    if category == 'developers'
      fetch_blog(locale: locale)
    else
      uri = URI.parse(CATEGORIES[category]['link'])
      uri.host = "#{locale}.#{uri.host}"
      uri.query = "page=#{page}"

      page = Nokogiri::HTML(Net::HTTP.get_response(uri).body)
      news = parse_news(page, locale) + parse_topics(page, locale)
      create_posts(locale: locale, news: news)
    end
  end

  def self.categories
    CATEGORIES.to_h.keys.freeze
  end

  def self.category(category)
    CATEGORIES[category]
  end

  def self.locales
    LOCALES
  end

  private
  def create_posts(locale:, news:)
    # Don't bother checking for new posts if all of the UIDs already exist
    if News.where(uid: news.pluck(:uid)).count == news.size
      []
    else
      news.filter_map do |post|
        unless News.exists?(uid: post[:uid])
          post = add_timestamps(post, locale) if post[:category] == 'maintenance' && timestamps_supported?(locale)
          News.create!(post)
        end
      end
    end
  end

  def format_time(time)
    Time.at(time).utc.strftime('%FT%TZ')
  end

  def parse_news(page, locale)
    page.css('li.news__list').map do |item|
      link = item.at_css('a')
      uri = URI.parse("#{BASE_URL}#{link['href']}")
      uri.host = "#{locale}.#{uri.host}"
      id = uri.to_s.split('/').last
      title = item.at_css('p').text.gsub(/\[.*\]/, '').strip
      time = item.css('script').text.scan(/\d+/).last.to_i

      category = case(link['class'])
                 when /ic__info/ then 'notices'
                 when /ic__maintenance/ then 'maintenance'
                 when /ic__update/ then 'updates'
                 when /ic__obstacle/ then 'status'
                 else raise ArgumentError.new("Unknown category for #{locale.upcase} news post #{id}: #{link['class']}")
                 end

      { uid: id, url: uri.to_s, title: title, time: format_time(time), locale: locale, category: category }
    end
  end

  def parse_topics(page, locale)
    page.css('li.news__list--topics').map do |item|
      uri = URI.parse("#{BASE_URL}#{item.at_css('p.news__list--title > a')['href']}")
      uri.host = "#{locale}.#{uri.host}"
      id = uri.to_s.split('/').last
      title = item.at_css('p.news__list--title').text.strip
      time = item.css('script').text.scan(/\d+/).last.to_i

      details = item.at_css('div.news__list--banner')
      image = details.at_css('img')['src']
      description = details.css('p').reject { |p| p.text.empty? }.first.children
        .map { |child| child.text.empty? ? ' ' : child.text.gsub(/\s{2,}/, ' ').gsub(/^\*/, "\n*") }
        .join.gsub('  ', "\n\n").strip

      { uid: id, url: uri.to_s, title: title, time: format_time(time), image: image, description: description,
        locale: locale, category: 'topics' }
    end
  end

  def parse_blog(page, locale)
    page.css('entry').map do |entry|
      url = entry.at_css('link')['href']
      id = entry.at_css('id').text
      title = entry.at_css('title').text.strip
      time = entry.at_css('published').text
      description = entry.at_css('content').text.gsub('<![CDATA[', '').split(/\n\s?{2,}/).select(&:present?)
        .first(2).map(&:strip).join("\n\n")

      { uid: id, url: url, title: title, time: time, description: description, locale: locale, category: 'developers' }
    end
  end
end
