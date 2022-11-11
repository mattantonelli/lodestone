module FeedsHelper
  def feed_language
    case action_name
    when 'na' then 'en'
    when 'eu' then 'en'
    when 'jp' then 'ja'
    else action_name
    end
  end

  def maintenance_description(post)
    if post.start_time.present?
      case action_name
      when 'na'
        "#{format_time(post, 'America/Los_Angeles')}<br>" \
          "#{format_time(post, 'America/New_York')}"
      when 'eu'
        description = format_time(post, 'GMT')
        description += "<br>#{format_time(post, 'Europe/London')}" if TZInfo::Timezone.get('Europe/London').dst?
        description += "<br>#{format_time(post, 'Australia/Melbourne')}"
        description
      when 'de'
        format_time(post, 'Europe/Berlin')
      end
    end
  end

  def format_time(post, zone)
    timezone = TZInfo::Timezone.get(zone)

    start_time, end_time = post.values_at(:start_time, :end_time).map do |time|
      next if time.nil?
      time = timezone.utc_to_local(time)

      if zone == 'Europe/Berlin'
        time.strftime("%-d. %b. %H:%M")
      else
        time.strftime("%a, %b %-d %-I:%M %p")
      end
    end

    if end_time.nil?
      timestamp = "#{start_time} (#{timezone.abbreviation})"
    else
      timestamp = "#{start_time} to #{end_time} (#{timezone.abbreviation})"
    end

    if zone == 'Europe/Berlin'
      timestamp = timestamp.gsub(/[A-Z]{3}(?=,)/i, Lodestone::I18N_DAYS['de'].invert)
        .gsub(/(?<=, )[A-Z]{3}/i, Lodestone::I18N_MONTHS['de'].invert)
        .sub(' to ', ' bis ')
        .sub('CET', 'MEZ')
        .sub('CEST', 'MESZ')
    end

    timestamp
  end
end
