module ApplicationHelper
  def flash_class(level)
    case level
    when /notice/  then 'alert-dark'
    when /success/ then 'alert-success'
    when /error/   then 'alert-danger'
    when /alert/   then 'alert-warning'
    end
  end

  def ga_tid
    Rails.application.credentials.dig(:google_analytics, :tracking_id)
  end
end
