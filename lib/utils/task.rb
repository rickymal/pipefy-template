class Task
    def initialize(ctx, pipe, reactor, input_queue, output_queue, services)
      @ctx = ctx
      @pipe = pipe
      @reactor = reactor
      @input_queue = input_queue
      @output_queue = output_queue
      @services = services
      ObjectSpace.define_finalizer(self, self.class.finalize(self))
    end

    def self.finalize(obj)
      return lambda do |status|
        obj.stop()
      end
    end

    def _create_pipe_task()
      create_pipe_task(@pipe, @reactor, @input_queue, @output_queue, @services)
    end

    def stop()
      self.on_stop()
    end
end