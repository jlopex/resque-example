require "bundler/setup"
require 'resque-status'

class WorkingJob

  include Resque::Plugins::Status
  @@queue  = :statused

  def self.set_queue(value)
    @@queue = value
  end

  def self.queue
    @@queue
  end

  def perform
    begin

      total = (options['length'] || 1).to_i
      num = 0
      progress = 0
      p "starting job"
      p "#{self.methods}"
      while num < total

        # poll redis
        at(num, total, "At #{n} of #{total}, progress #{progress}")

        p "before sleep"
        sleep(1)
        progress = num * 100/total
        p num
        options['testing'] = 'hello'
        options['progress'] = progress.to_s
        num += 1
      end
    rescue Killed
      msg =  "task was killed by sample app"
      p msg
      failed(msg)

    rescue Resque::TermException # write failure to database end
      msg = "sigterm exception"
      p msg
      failed(msg)
    end
  end

end
