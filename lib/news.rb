module News
  extend self
  extend NewsCache

  BASE_URL = 'http://na.finalfantasyxiv.com'.freeze
  CATEGORIES = OpenStruct.new(YAML.load_file('config/categories.yml')).freeze

  def fetch(type)
    name = type.downcase
    category = CATEGORIES[name]
    raise ArgumentError if category.nil?

    if stale?(name)
      page = Nokogiri::HTML(open(category['url']))
      news = parse(page, name)
      cache(news, name)
      news
    else
      cached(name)
    end
  end

  def categories
    CATEGORIES
  end

  private
  def parse(page, type)
    if type == 'topics'
      parse_topics(page)
    else
      parse_news(page)
    end
  end

  def parse_news(page)
    page.css('li.news__list').map do |item|
      url = "#{BASE_URL}#{item.at_css('a')['href']}"
      id = url.split('/').last
      title = item.at_css('p').text.gsub(/\[.*\]/, '')
      time = item.css('script').text.scan(/\d+/).last.to_i

      { id: id, url: url, title: title, time: format_time(time) }
    end
  end

  def parse_topics(page)
    page.css('li.news__list--topics').map do |item|
      url = "#{BASE_URL}/#{item.at_css('p.news__list--title > a')['href']}"
      id = url.split('/').last
      title = item.at_css('p.news__list--title').text
      time = item.css('script').text.scan(/\d+/).last.to_i

      details = item.at_css('div.news__list--banner')
      image = details.at_css('img')['src']
      description = details.css('p').children.first.text

      { id: id, url: url, title: title, time: format_time(time), image: image, description: description }
    end
  end

  def format_time(time)
    Time.at(time).utc.strftime('%FT%TZ')
  end
end
