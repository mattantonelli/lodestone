module Maintenance
  extend self

  DATE_REGEX = {
    'na' => /\[Date & Time\](.*?)(?:\[|\z)/im,
    'eu' => /\[Date & Time\](.*?)(?:\[|\z)/im,
    'de' => /\[Datum & (?:Zeit|Uhrzeit)\](.*?)(?:\[|\z)/im
  }.freeze

  TIMESTAMP_REGEX = {
    'na' => /(\w{3}\.? \d{1,2}, \d{4})? (?:from )?(\d{1,2}:\d{2}(?: [ap]\.m\.)?)(?: \((\w+)\))?/i,
    'eu' => /(\w{3}\.? \d{1,2}, \d{4})? (?:from )?(\d{1,2}:\d{2}(?: [ap]\.m\.)?)(?: \((\w+)\))?/i,
    'de' => /(\d{1,2}\. \w{3}\.? \d{4})? (?:von |um )?(\d{1,2}(?::\d{2})? Uhr)(?: \((\w+)\))?/i
  }.freeze

  I18N_MONTHS = {
    'de' => { 'Jan' => 'Jan', 'Feb' => 'Feb', 'Mär' => 'Mar', 'Apr' => 'Apr', 'Mai' => 'May', 'Jun' => 'Jun',
              'Jul' => 'Jul', 'Aug' => 'Aug', 'Sep' => 'Sep', 'Okt' => 'Oct', 'Nov' => 'Nov', 'Dez' => 'Dec' }
  }.freeze

  I18N_DAYS = {
    'de' => { 'So' => 'Sun', 'Mo' => 'Mon', 'Di' => 'Tue', 'Mi' => 'Wed', 'Do' => 'Thu', 'Fr' => 'Fri', 'Sa' => 'Sat' }
  }.freeze

  def add_timestamps(news, type, locale)
    key = "#{locale}-#{type}-timestamps"

    news.map do |post|
      if Redis.current.hexists(key, post[:id])
        timestamps = JSON.parse(Redis.current.hget(key, post[:id]), symbolize_names: true)
        post.merge(timestamps)
      else
        begin
          page = Nokogiri::HTML(open(post[:url]))
          details = page.at_css('.news__detail__wrapper').text.match(DATE_REGEX[locale])[0]
          times = details.scan(TIMESTAMP_REGEX[locale])
          times << [nil, nil, nil] if times.size == 1 # Ensure we have at least one start/end time pair
          times = times.take((times.size / 2) * 2) # Only take times in pairs

          # Add missing date/time zone to each time pair using data from the paired time
          times.each_slice(2) do |slice|
            slice[0][2] ||= slice[1][2]
            slice[1][0] ||= slice[0][0]
          end

          start_time, end_time = [times.first, times.last].map do |time|
            next if time.any?(&:nil?)
            parse_time(time.join(' '), locale)
          end

          Redis.current.hset(key, post[:id], { start: start_time, end: end_time }.to_json)
          post[:start] = start_time
          post[:end] = end_time
          post
        rescue Exception => e
          LodestoneLogger.error("Fatal error adding timestamps for #{post[:url]}")
          LodestoneLogger.error(e.to_s)
          post.merge(start: nil, end: nil)
        end
      end
    end
  end

  def filter_maintenance(posts, title)
    time = Time.now
    latest = posts.select { |post| post[:title].downcase.match?(title.downcase) }
      .reject { |post| post[:start].nil? || post[:end].nil? }
      .select { |post| time <= Time.parse(post[:end]) }
      .sort_by { |post| post[:start] }
      .first

    if latest
      latest[:emergency] = latest[:title].downcase.match?('emergency')
      latest[:current] = time >= Time.parse(latest[:start])
    end

    latest
  end

  def timestamps_supported?(locale)
    TIMESTAMP_REGEX.keys.include?(locale)
  end

  private
  def parse_time(time, locale)
    time = time.sub(/(BST|MEZ)/, '+0100')
      .sub('MESZ', '+0200')

    if locale == 'de'
      time = time.gsub(/(?<!:\d{2}) Uhr/, ':00')
        .gsub(' Uhr', '')
        .sub(/[A-Z]{3}/i, I18N_MONTHS['de'])
    end

    Time.parse(time).utc.strftime('%FT%TZ')
  end
end
