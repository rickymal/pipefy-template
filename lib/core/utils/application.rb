module Lotus
  class Application
    attr_reader :tasks

    def on(event, &action)
      @event_emitters[event] = action
    end

    def stop()
      self.update_status 'stopping'
      @tasks.each do |task|
        task.stop()
      end
      self.update_status 'stopped'
    end


    def get_pipeline_queues()
      return @queues
    end


    def throw_pipeline(exception)
      
      self.update_status 'erroring'
      @tasks.each do |task|
        task.on_error(exception) if task.respond_to? 'on_error'
        
      end
      self.update_status 'error'
    end


    def initialize(activities, global_services, &blk)
      pipe_flow = QueuePathBuilder.new
      @activities = activities
      @event_emitters = Hash.new()
      @queues = Array.new()
      
      
      if self.respond_to? :reactor 
        reactor = self.reactor()
      else
        reactor = Async::Task.current()
      end
      
      input_queue, output_queue = pipe_flow.next
      
      @queues << input_queue
      @queues << output_queue

      @input_queue = input_queue
      @tasks = [] 
      
      @activities.each do |activity|
        
        pipe, executor, services = activity
        pipe.include Lotus::DefaultInitializer
        task = Task.new(self, pipe, reactor, input_queue, output_queue, services)
        task.singleton_class.include executor
        
        task._create_pipe_task()
        @tasks << task

        # pipe_instance = pipe.create_pipe_task(reactor, input_queue, output_queue, service) rescue 
        input_queue, output_queue = pipe_flow.next
        @output_queue = input_queue
        @queues << input_queue
        @queues << output_queue
      end
      @queues.uniq!()
      if blk
        Async do
          while (response = @output_queue.dequeue) != END_APP
            
            blk.call response
          end
        end
      end
    end

    def call(data_in = nil)
      @input_queue.enqueue data_in
    end
end
end