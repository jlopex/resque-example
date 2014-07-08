require 'bundler/setup'
require 'resque-status'
require File.expand_path(File.dirname(__FILE__) + '/job') 

require './app.rb'

class SampleApp

  def queue_from_priority(priority)
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

  def dequeue(uuid)
    WorkingJob.set_queue(job_queue(uuid))
    WorkingJob.dequeue(WorkingJob, uuid)
  end

  def enqueue(priority = 5, xml = '<job>job here</job>')
    queue = queue_from_priority(priority)
    p "Assigned to queue #{queue}"
    job_id = WorkingJob.enqueue_to(queue.to_sym, WorkingJob, :length => 100, :priority => priority, :xml=> xml)
    p "Got back uuid #{job_id}"
  end

  def job_options(uuid)
    status = Resque::Plugins::Status::Hash.get(uuid)
    return status['options'] if status
    nil
  end

  def job_status(uuid)
    # returns queued,processing, etc
    status = Resque::Plugins::Status::Hash.get(uuid)
    return status['status'] if status
    nil
  end

  def job_created(uuid)
    status = Resque::Plugins::Status::Hash.get(uuid)
    return status['time'] if status
    nil
  end

  def job_queued?(uuid)
   job_status(uuid) == Resque::Plugins::Status::STATUS_QUEUED
  end

  def job_failed?(uuid)
    job_status(uuid) == Resque::Plugins::Status::STATUS_FAILED
  end

  def job_working?(uuid)
    job_status(uuid) == Resque::Plugins::Status::STATUS_WORKING
  end

  def job_completed?(uuid)
    job_status(uuid) == Resque::Plugins::Status::STATUS_COMPLETED
  end

  def job_queue(uuid)
    queue_from_priority(job_options(uuid)['priority'].to_i)
  end

  def change_priority(uuid, new_priority)
    options = job_options(uuid)
    if new_priority != options['priority'] && job_queued?(uuid)
      dequeue(uuid)
      enqueue(new_priority, options['xml'])
    end
  end

  def peek(queue = :statused)
    p "Peek jobs at queue #{queue}"
    p Resque.peek(queue.to_sym, 0, Resque.size(queue.to_sym))
  end

  def peek_next(queue = :statused)
    Resque.peek(queue.to_sym)
  end

  def peek_job(job_index, queue = :statused)
    p "Peek jobs at queue position #{job_index}"
    p Resque.peek(queue.to_sym, job_index, 1)
  end

  def resque_info
    info = Resque.info
    p "resque info #{info}"
  end

  def list_jobs
    Resque.queues.each do |qname|
      p "jobs in #{qname}"
      peek(qname)
    end
  end

  def destroy_all_queues
    names = Resque.queues
    names.each do |name|
      destroy_queue(name)
    end
  end
 
  def destroy_queue(name)
    p "destroying queue #{name}"
    Resque.remove_queue(name)
  end

  def status(uuid)
    status = Resque::Plugins::Status::Hash.get(uuid)
    if status
      p "status[job #{uuid}]: #{status}"
      return status
    else
      p "job not found"
    end
    nil
  end

  def kill(uuid)
    p "killing job #{uuid}"
    Resque::Plugins::Status::Hash.kill(uuid)
  end


  def dequeue_uuid(uuid)
    size = Resque.size(:statused)
    p "Dequeueing #{uuid}, before dequeue there are #{Resque.size(:statused)} jobs"
    WorkingJob.dequeue(WorkingJob, uuid)
    if (size-1 == Resque.size(:statused))
      puts "#{uuid}...dequeued"
    end
  end
 
  def queue_size
    size = Resque.size(:statused)
    puts "Statused contains: #{size} elements."
  end    

  def queues
    p Resque.queues
  end

  def workers
    p "no workers" if Resque.workers.empty?
    Resque.workers.each do |worker|
      p worker
      p "running job:"
      p worker.job['payload']['args'].first
    end
  end

  def working
    p "no working workers" if Resque.working.empty?
    Resque.working.each do |worker|
      p worker.inspect
      p worker.hostname
      p "running job:"
      p worker.job['payload']['args'].first
    end
  end

  def redis
    p Resque.redis
  end

end

cmd = ARGV[0]
arg = ARGV[1]
arg2 = ARGV[2]
rq = SampleApp.new()
# sample.run()
case cmd

  when 'kill'
    rq.kill(arg)
  when 'peek_job'
    rq.peek_job(arg)
  when 'peek'
    rq.peek(arg)
  when 'peek_next'
    rq.peek_next
  when 'dequeue'
    rq.dequeue(arg)
  when 'size'
    rq.queue_size
  when 'enqueue'
    rq.enqueue(arg)
  when 'destroy'
    rq.destroy_all_queues
  when 'queues'
    rq.queues
  when 'status'
    rq.status(arg)
  when 'workers'
    rq.workers
  when 'working'
    rq.working
  when 'dequeue_uuid'
    rq.dequeue_uuid(arg)
  when 'resque_info'
    rq.resque_info
  when 'redis'
    rq.redis
  when 'change_priority'
    rq.change_priority(arg, arg2)
  when 'list_jobs'
    rq.list_jobs
end


