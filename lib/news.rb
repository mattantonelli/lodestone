module News
  require_relative 'news_cache.rb'

  extend self
  extend Maintenance
  extend NewsCache

  BASE_URL = 'http://finalfantasyxiv.com'.freeze
  CATEGORIES = OpenStruct.new(YAML.load_file('config/categories.yml')).freeze
  GREETINGS = YAML.load_file('config/greetings.yml').freeze
  WEBHOOK_URL_FORMAT = /https:\/\/discord.com\/api\/webhooks\/\d+\/.+/.freeze

  def fetch(type, locale, skip_cache = false)
    category = CATEGORIES[type]
    raise ArgumentError if category.nil?

    if skip_cache || stale?(type, locale)
      uri = URI.parse(category['url'])
      uri.host = "#{locale}.#{uri.host}"
      begin
        page = Nokogiri::HTML(open(uri))
        news = parse(page, type, locale)
        news = add_timestamps(news, type, locale) if type == 'maintenance' && timestamps_supported?(locale)
        cache(news, type, locale)
        news
      rescue OpenURI::HTTPError => e
        # Could not fetch new data, so log the error and return the latest cached data
        LodestoneLogger.error("Error contacting the Lodestone: #{e.to_s}")
        cached(type, locale)
      rescue RuntimeError => e
        # Lodestone is undergoing maintenance which results in a redirect, return the latest cached data
        LodestoneLogger.error("Error contacting the Lodestone: #{e.to_s}")
        cached(type, locale)
      rescue Exception => e
        LodestoneLogger.error("Fatal error fetching news: #{e.to_s}")
        e.backtrace.each { |line| LodestoneLogger.error(line) }
        cached(type, locale)
      end
    else
      cached(type, locale)
    end
  end

  def all(locale)
    CATEGORIES.to_h.keys.each_with_object({}) do |type, h|
      h[type] = fetch(type.to_s, locale)
    end
  end

  def feed(locale)
    feed = CATEGORIES.to_h.keys.flat_map do |type|
      posts = fetch(type.to_s, locale)
      posts.each { |post| post[:category] = type }
    end

    feed.sort_by { |post| post[:time] }.reverse.first(20)
  end

  def current_maintenance(locale)
    posts = fetch('maintenance', locale)

    {
      companion: filter_maintenance(posts, 'Companion'),
      game: filter_maintenance(posts, 'World'),
      lodestone: filter_maintenance(posts, 'Lodestone'),
      mog: filter_maintenance(posts, 'Mog Station'),
      psn: filter_maintenance(posts, 'PSN')
    }
  end

  def subscribe(params, locale, validate = false)
    url = params['url']

    if validate
      raise ArgumentError unless url =~ WEBHOOK_URL_FORMAT
    end

    redis = Redis.current

    status = CATEGORIES.to_h.keys.map(&:to_s).each_with_object({}) do |category, h|
      choice = params[category].to_s
      key = "#{locale}-#{category}-webhooks"

      if choice == '1'
        redis.sadd(key, url)
        h[category] = true
      elsif choice == '0'
        redis.srem(key, url)
        h[category] = false
      else
        h[category] = redis.sismember(key, url)
      end
    end

    # Send a notification if the webhook is newly subscribed
    if status.values.any? && !Redis.current.sismember('all-webhooks', url)
      Webhooks.send_message(url, "#{GREETINGS[locale]} <#{HOSTS[locale]}>")
      Redis.current.sadd('all-webhooks', url)
    end

    status
  end

  def categories
    CATEGORIES
  end

  private
  def parse(page, type, locale)
    if type == 'topics'
      parse_topics(page, locale)
    elsif type == 'developers'
      parse_developers_blog(page)
    else
      parse_news(page, locale)
    end
  end

  def parse_news(page, locale)
    page.css('li.news__list').map do |item|
      uri = URI.parse("#{BASE_URL}#{item.at_css('a')['href']}")
      uri.host = "#{locale}.#{uri.host}"
      id = uri.to_s.split('/').last
      title = item.at_css('p').text.gsub(/\[.*\]/, '').strip
      time = item.css('script').text.scan(/\d+/).last.to_i

      { id: id, url: uri.to_s, title: title, time: format_time(time) }
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

      { id: id, url: uri.to_s, title: title, time: format_time(time), image: image, description: description }
    end
  end

  def parse_developers_blog(page)
    page.css('entry').map do |entry|
      url = entry.at_css('link')['href']
      id = entry.at_css('id').text
      title = entry.at_css('title').text.strip
      time = entry.at_css('published').text
      description = entry.css('content > p').first(2).map { |p| p.text.strip }.reject(&:empty?).join("\n\n")

      { id: id, url: url, title: title, time: time, description: description }
    end
  end

  def format_time(time)
    Time.at(time).utc.strftime('%FT%TZ')
  end
end
