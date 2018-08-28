module Scheduler
  extend self

  def run
    scheduler = Rufus::Scheduler.new(lockfile: 'tmp/.rufus-scheduler.lock')

    def scheduler.on_error(job, error)
      LodestoneLogger.error(error.inspect)
      error.backtrace.each { |line| LodestoneLogger.error(line) }
    end

    scheduler.cron('5,20,35,50 * * * *') do
      Webhooks.execute_all
    end

    scheduler.cron('0,15,30,45 * * * *') do
      WebhooksResend.send_all
    end
  end
end
