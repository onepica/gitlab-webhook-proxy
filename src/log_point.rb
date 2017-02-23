require 'configatron'
require 'logger'

module GitlabHook
  module LogPoint
    @loggers = {}

    module_function

    ##
    # Write log message
    #
    # @param [Object|String] data
    # @param [String] name
    # @param [String] level
    #
    def write(data, name = 'global', level = Logger::INFO)
      if level == 'info'
        level = Logger::INFO
      elsif level == 'debug'
        level = Logger::DEBUG
      elsif level == 'warn'
        level = Logger::WARN
      elsif level == 'fatal'
        level = Logger::FATAL
      else
        level = Logger::UNKNOWN
      end

      logger(name).add(level) { data.to_s }
    end

    ##
    # Get logger
    #
    # @param [String] name
    # @param [String] threshold
    # @return [Logger]
    #
    def logger(name,
               threshold: Logger::UNKNOWN,
               message_format: "%<datetime>s: %<msg>s \n",
               datetime_format: '%Y%m%d-%H%M%S')
      return @loggers[name] if @loggers[name]

      raise 'LFI protection' if name.index '../'

      # Leave 10 “old” log files where each file is about 1,024,000 bytes.
      file = File.join(configatron.app.path.logs, '/' + name + '.log')
      @loggers[name] = Logger.new(
          file, 10, 1024000
      )
      @loggers[name].formatter = proc do |severity, datetime, progname, msg|
        data = {
            severity: severity,
            datetime: datetime,
            progname: progname,
            msg: msg,
        }
        sprintf message_format, data
      end
      @loggers[name].sev_threshold = threshold
      @loggers[name].datetime_format = datetime_format

      @loggers[name]
    end
  end
end
