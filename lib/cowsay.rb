require 'active_support'
require 'logger'
module Cowsay
  class Cow
    def initialize(options={})
      @io_class = options.fetch(:io_class){IO}
      @logger   = options.fetch(:logger){Logger.new($stderr)}
    end

    def say(message, options={})
      assert(options[:cowfile].nil? || File.exist?(options[:cowfile]))
      command = "cowsay"
      if options[:strings] && options[:strings][:eyes]
        command << " -e '#{options[:strings][:eyes]}'"
      end
      if options[:cowfile]
        command << " -f #{options[:cowfile]}"
      end

      messages = case message
                 when Array then message
                 when nil then []
                 else [message]
                 end
      results = []
      messages.each do |message|
        @io_class.popen(command, "w+") do |process|
          results << begin
                       process.write(message)
                       process.close_write
                       result = process.read
                     rescue Errno::EPIPE
                       message
                     end
        end
      end
      output = results.join("\n")    
      if options[:out]
        options[:out] << output
      end
      destination = case options[:out]
                    when nil  then "return value"
                    when File then options[:out].path
                    else options[:out].inspect
                    end
      @logger.info "Wrote to #{destination}"
      if $? && ![0,172].include?($?.exitstatus)
        raise ArgumentError, "Command exited with status #{$?.exitstatus.to_s}"
      end
      output
    end

  private
    
    def assert(value, message="Assertion failed")
      raise Exception, message, caller unless value
    end
  end
end
