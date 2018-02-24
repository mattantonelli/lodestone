module Characters
  extend self
  extend Cache

  JOBS = %w(PLD WAR DRK WHM SCH AST MNK DRG NIN SAM BRD MCH BLM SMN RDM CRP BSM ARM GSM LTW WVR ALC CUL MIN BTN FSH).freeze

  def fetch(name, world, skip_cache = false)
    raise ArgumentError if name&.empty? || world&.empty?
    key = key(name, world)

    if skip_cache || stale?(:characters, key)
      data = parse(name, world)
      cache(:characters, key, data)
      data
    else
      cached(:characters, key)
    end
  end

  def clean
    keys = Redis.current.hgetall('characters-timestamps').map do |key, timestamp|
      # Find any character data older than 6 hours
      key if Time.now > Time.parse(timestamp) + 21600
    end

    Redis.current.hdel('characters-data', keys)
    Redis.current.hdel('characters-timestamps', keys)
  end

  def key(name, world)
    "#{world}-#{name.gsub(' ', '-')}".downcase
  end

  private
  def parse(name, world)
    search_url = "#{BASE_URL}/lodestone/character/?q=#{name.gsub(' ', '+')}&worldname=#{world.capitalize}"
    search = Nokogiri::HTML(open(search_url))

    character_link = search.at_css('.entry > a.entry__link')
    raise ArgumentError if character_link.nil?
    character_url = "#{BASE_URL}#{character_link['href']}"
    page = Nokogiri::HTML(open(character_url))

    character = { url: character_url }

    character[:name] = page.at_css('.frame__chara__name').text
    character[:title] = page.at_css('.frame__chara__title')&.text
    character[:world] = page.at_css('.frame__chara__world').text

    race, clan, gender = page.css('.character-block__name')[0].inner_html.split(/<br>| \/ /)
    character.merge!(race: race, clan: clan, gender: gender)

    character[:nameday] = page.at_css('.character-block__birth').text
    character[:guardian] = page.css('.character-block__name')[1].text
    character[:city] = page.css('.character-block__name')[2].text

    grand_company, rank = page.css('.character-block__name')[3]&.text&.split(' / ')
    character.merge!(grand_company: grand_company, grand_company_rank: rank)

    character[:free_company] = page.at_css('.character__freecompany__name > h4 > a')&.text

    level_numbers = page.css('.character__level__list > ul > li').map(&:text)
    character[:levels] = JOBS.zip(level_numbers).to_h

    character
  end
end
