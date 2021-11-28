require 'open-uri'

module Lodestone
  BASE_URL = 'https://finalfantasyxiv.com'.freeze
  CATEGORIES = OpenStruct.new(YAML.load_file('config/categories.yml')).freeze
  LOCALES = %w(na eu fr de jp).freeze

  extend self

  def fetch(locale:, category:, skip_cache: false)
    config = CATEGORIES[category]

    uri = URI.parse(config['url'])
    uri.host = "#{locale}.#{uri.host}"

    begin
      page = Nokogiri::HTML(URI.open(uri))
      news = parse(page, locale, category)

      news.each do |post|
        News.create!(post) unless News.exists?(uid: post[:uid])
      end
    end
  end

  def fetch_all(locale:)
    Lodestone.categories.each do |category|
      news = fetch(locale: locale, category: category.to_s)
    end
  end

  def self.categories
    CATEGORIES.to_h.keys.freeze
  end

  def self.locales
    LOCALES
  end

  private
  def format_time(time)
    Time.at(time).utc.strftime('%FT%TZ')
  end

  def parse(page, locale, category)
    if category == 'topics'
      parse_topics(page, locale, category)
    elsif category == 'developers'
      parse_developers_blog(page, locale, category)
    else
      parse_news(page, locale, category)
    end
  end

  def parse_news(page, locale, category)
    page.css('li.news__list').reverse.map do |item|
      uri = URI.parse("#{BASE_URL}#{item.at_css('a')['href']}")
      uri.host = "#{locale}.#{uri.host}"
      id = uri.to_s.split('/').last
      title = item.at_css('p').text.gsub(/\[.*\]/, '').strip
      time = item.css('script').text.scan(/\d+/).last.to_i

      { uid: id, url: uri.to_s, title: title, time: format_time(time), locale: locale, category: category }
    end
  end

  def parse_topics(page, locale, category)
    page.css('li.news__list--topics').reverse.map do |item|
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
        locale: locale, category: category }
    end
  end

  def parse_developers_blog(page, locale, category)
    page.css('entry').reverse.map do |entry|
      url = entry.at_css('link')['href']
      id = entry.at_css('id').text
      title = entry.at_css('title').text.strip
      time = entry.at_css('published').text
      description = entry.css('content > p').first(2).map { |p| p.text.strip }.reject(&:empty?).join("\n\n")

      { uid: id, url: url, title: title, time: time, description: description, locale: locale, category: category }
    end
  end
end
