require 'async'

class Promise
  def initialize
    @task = nil
    @result = nil
    @error = nil
  end

  def run(&block)
    raise "Promise already running" if @task

    @task = Async do |task|
      begin
        @result = block.call(task)
      rescue Exception => e
        @error = e
      end
    end

    self
  end

  def then(&block)
    raise "Promise not running" unless @task

    @task.wait

    if @error
      raise @error
    else
      block.call(@result) if block_given?
    end
  end
end

# Create a new Promise instance
promise = Promise.new

Async do |task|
  # Run a block asynchronously
  promise.run do
    sleep 1
    "Result from async block"
  end

  # Handle the result or error
  promise.then do |result|
    puts "Result: #{result}"
  end

  task.children.each(&:wait) # Wait for all child tasks to complete
end
