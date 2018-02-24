module Scheduler
  extend self

  def run
    scheduler = Rufus::Scheduler.new(lockfile: 'tmp/.rufus-scheduler.lock')

    def scheduler.on_error(job, error)
      LodestoneLogger.error(error.inspect)
      error.backtrace.each { |line| LodestoneLogger.error(line) }
    end

    scheduler.cron('5,35 * * * *') do
      Webhooks.execute_all
    end

    scheduler.cron('10,40 * * * *') do
      WebhooksResend.send_all
    end

    scheduler.cron('0 0 * * *') do
      Characters.clean
    end
  end
end
