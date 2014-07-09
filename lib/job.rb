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

  def self.queue_from_priority(priority)
    case priority.to_i
      when 0, 1, 2
        'low'
      when 3, 4, 5
        'medium'
      when 6, 7, 8
        'high'
      when 9
        'ultra'
      else
        'statused'
    end
  end

  def perform
    begin
      p "options['priority'] #{options['priority']}"
      qname = WorkingJob.queue_from_priority(options['priority'])

      WorkingJob.set_queue(qname)
      total = (options['length'] || 1).to_i
      num = 0
      progress = 0

      while num < total
        p "gets here, queue is #{@@queue}"
        # poll redis
        at(num, total, "At #{num} of #{total}, progress #{progress}")

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
