module Scheduler
  extend self

  def run
    scheduler = Rufus::Scheduler.new

    scheduler.cron('5,35 * * * *') do
      Webhooks.execute_all
    end
  end
end
