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
      p "queues #{worker.queues}"
      p "hostname #{worker.hostname}"
      p "failed #{worker.failed}"
      p "processed #{worker.processed}"
      p "started #{worker.started}"

      p "running job #{worker.job['payload']['args'].first}" if worker.working?

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
    # p Resque.redis.keys
    #Resque.redis = 'hostname:port:db'  # all 3 values are optional
    p Resque.redis.client.host
    p Resque.redis.client.port
    p Resque.redis
  end

  def failed
    cnt = Resque::Failure.count
    Resque::Failure.all(0,cnt).each do |job|
      p"-------------"
      p job['payload']['args'].first
      p job
    end
  end

  def clear_failed_queue
    Resque::Failure.clear
  end

  def requeue(uuid, remove_from_failed = true)
    cnt = Resque::Failure.count
    Resque::Failure.all(0,cnt).each_with_index do |job, i|
      if uuid == job['payload']['args'].first
        Resque::Failure.requeue(i)
        Resque::Failure.remove(i) if remove_from_failed
      end
    end
  end
end

cmd = ARGV[0]
uuid = ARGV[1]
arg2 = ARGV[2]
rq = SampleApp.new()
# sample.run()
case cmd

  # job commands
  when 'kill'
    rq.kill(uuid)
  when 'status'
    #{\"time\"=>1404887934, \"status\"=>\"queued\", \"uuid\"=>\"..\", \"options\"=>{..}}
    rq.status(uuid)
  when 'change_priority'
    rq.change_priority(uuid, arg2)
  when 'list_jobs'
    rq.list_jobs
  when 'enqueue'
    prio = ARGV[1]
    rq.enqueue(prio)

  # queue commands
  when 'peek_job'
    rq.peek_job(uuid)
  when 'peek'
    rq.peek(uuid)
  when 'peek_next'
    rq.peek_next
  when 'dequeue'
    rq.dequeue(uuid)
  when 'size'
    rq.queue_size

  # queues commands
  when 'destroy'
    rq.destroy_all_queues
  when 'queues'
    # ["ultra", "low"]
    rq.queues


  # worker commands
  when 'workers'
    #for each worker
    # worker queues i.e ["ultra"], jobs, hostname
    rq.workers
  when 'working'
    rq.working


  # resque info commands
  when 'resque_info'
    rq.resque_info
  when 'redis'
    rq.redis


  # failure management
  when 'failed'
    rq.failed
  when 'requeue'
    rq.requeue(uuid)

end


