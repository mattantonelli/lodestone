class LodestoneLogger
  extend SingleForwardable

  def_delegators :logger, :info, :error, :warn, :level

  class << self
    def logger
      if @logger.nil?
        file = File.new("log/#{ENV['RACK_ENV']}.log", 'a')
        file.sync = true
        @logger = Logger.new(file)
      end

      @logger
    end
  end
end
