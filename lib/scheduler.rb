module Scheduler
  extend self

  def run(logger)
    scheduler = Rufus::Scheduler.new(lockfile: 'tmp/.rufus-scheduler.lock')

    scheduler.cron('5,35 * * * *') do
      Webhooks.execute_all(logger)
    end
  end
end
