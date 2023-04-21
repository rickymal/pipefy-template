module Lotus
  module Method
    module Stream 
        def on_stop()
            puts "Parando aplicação #{self}"
            puts "Parando aplicação #{self}"
            
            @tsk.stop()
            @instance = nil
          end
    
          def on_error(exception = nil)
            # binding.pry
            # @tsk.stop()
            # binding.pry
            @instance = nil
          end
    
          def create_pipe_task(pipe, reactor, input_queue, output_queue, services)
            
            @instance = pipe.new
            if @instance.respond_to? "_lotus_service_loading"
              @instance._lotus_service_loading(services)
            end
            
            @tsk = reactor.async do 
              while (response = input_queue.dequeue) != END_APP
                @instance.call(response) do |yld|
                  output_queue.enqueue yld
                end
              end
            end
          end
    end
end
end