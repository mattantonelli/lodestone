module Scheduler
  extend self

  def run
    scheduler = Rufus::Scheduler.new(lockfile: 'tmp/.rufus-scheduler.lock')

    def scheduler.on_error(job, error)
      LodestoneLogger.error(error.inspect)
      error.backtrace.each { |line| LodestoneLogger.error(line) }
    end

    unless scheduler.down?
      scheduler.cron('5,15,25,35,45,55 * * * *') do
        Webhooks.execute_all
      end

      scheduler.cron('0,10,20,30,40,50 * * * *') do
        WebhooksResend.send_all
      end
    end
  end
end
