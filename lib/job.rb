require "bundler/setup"
require 'resque-status'

class WorkingJob

  include Resque::Plugins::Status

  def perform
    p "Starting"
    total = (options['length'] || 1000).to_i
    num = 0
    while num < total
      p "#{num}"
      at(num, total, "At #{num} of #{total}")
      sleep(1)
      num += 1
    end
    p "Ended!"
  rescue SignalException
    p "TERM!!!!!!"
    sleep(2)
  end

end

class BasicJob
  include Resque::Plugins::Status
end
