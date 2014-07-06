require 'bundler/setup'
require 'resque-status'
require File.expand_path(File.dirname(__FILE__) + '/job') 

class SampleApp

  def run
    enqueue_10_def
    dequeue_fifth
    get_queue_size
    get_status_1st
    destroy_all_queues
    enqueue
    get_queue_size
    dequeue
    get_queue_size
    get_resque_info
    destroy_all_queues
  end

  def enqueue_10_def
    @jobs = Array.new(10)
    for i in 0..9
      # Remember use the resque-status way! :-)
      job_id = BasicJob.enqueue(:length => 100)
      puts "Got back #{job_id}"
      @jobs[i] = job_id
    end

    size = Resque.size(:statused)
    BasicJob.dequeue(WorkingJob, job_id)
    if (size-1 == Resque.size(:statused))
      puts "IUEEEEEEEEEE"
    end
  end

  def get_resque_info
    info = Resque.info
    puts "There are #{info[:pending]} tasks pending."
  end  

  def destroy_all_queues
    names = Resque.queues
    names.each do |name|
      destroy_queue(name)
    end
  end
 
  def destroy_queue (name)
    Resque.remove_queue(name)
  end

  def get_status_1st 
    status = Resque::Plugins::Status::Hash.get(@jobs.at(0))
    puts status.inspect
  end
    
  def kill_2nd
    Resque::Plugins::Status::Hash.kill(@jobs.at(1))
  end
 
  def dequeue_fifth
    size = Resque.size(:statused)
    BasicJob.dequeue(WorkingJob, @jobs.at(4))
    if (size-1 == Resque.size(:statused))
      puts "OK 5th!"
    end
  end
 
  def enqueue
    @uuid1 = BasicJob.enqueue(WorkingJob, :num => 100)
    @uuid2 = BasicJob.enqueue(WorkingJob, :num => 100)
  end

  def dequeue
    size = Resque.size(:statused)
    BasicJob.dequeue(WorkingJob, @uuid1)
    if (size-1 == Resque.size(:statused))
      puts "OK!"
    end
  end

  def get_queue_size
    size = Resque.size(:statused)
    puts "Statused contains: #{size} elements."
  end    

end

if __FILE__ == $0
  sample = SampleApp.new()
  sample.run()
end
