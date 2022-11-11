module FeedsHelper
  def feed_language
    case action_name
    when 'na' then 'en'
    when 'eu' then 'en'
    when 'jp' then 'ja'
    else action_name
    end
  end

  def feed_title
    "#{action_name.upcase} Lodestone News"
  end
end
