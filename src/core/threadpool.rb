require 'async'
require 'async/queue'

class FixedThreadPool
  def initialize(size)
    @size = size
    # @task_queue = Queue.new
    @task_queue = Async::LimitedQueue.new (2*size)
    @workers = []
  end

  def start
    @size.times do |i|
      @workers << Async do |task|
        while (job = @task_queue.dequeue)
          job.call(task)
        end
      end
    end
  end

  def stop
    @size.times do
      @task_queue << nil
    end
    @workers.each(&:wait)
  end

  def post(&block)
    @task_queue << block
  end
end


# Create a new FixedThreadPool instance with 4 worker tasks
thread_pool = FixedThreadPool.new(4)

Async do 
    # Start the worker tasks
    thread_pool.start
    
    # Post jobs to the thread pool
    10.times do |i|
      thread_pool.post do |task|
        sleep rand(0.5..2)
        puts "Job #{i} completed by task #{task}"
      end
    end
    
    # Give the tasks some time to finish the jobs
    sleep 10
end
