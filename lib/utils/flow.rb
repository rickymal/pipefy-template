module Lotus
  module Method
    module Flow
        def on_stop()
            @tsk.stop()
            @instance = nil
          end
    
          def on_error(exception = nil)
            @instance = nil
          end
    
          def create_pipe_task(pipe, reactor, input_queue, output_queue, services)
            @input_queue = input_queue
            @instance = pipe.new()
            if @instance.respond_to? "_lotus_service_loading"
              @instance._lotus_service_loading(services)
            end
    
            @tsk = reactor.async do
              while (response = input_queue.dequeue) != END_APP
                begin
                  resp = @instance.call(response)
                rescue CustomException => exception
                  @ctx.throw_pipeline(exception)
                else
                  output_queue.enqueue resp
                end
              end
            end
          end
    end
end
end