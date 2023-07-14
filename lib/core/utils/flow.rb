module Lotus
  module Method
    module Flow
      attr_reader :method_status

      def on_stop()
        @method_status = {
          status: 'stopped',
          msg: nil
        }
        if @tsk
          @tsk.stop()
        end
        @instance = nil
      end

      def on_error(exception = nil)
        @method_status = {
          status: 'error',
          msg: exception
        }
        @instance = nil
      end

      def create_pipe_task(pipe, reactor, input_queue, output_queue, services)
        
        @input_queue = input_queue
        @instance = pipe.new()
        if @instance.respond_to? "_lotus_service_loading"
          @instance._lotus_service_loading(services)
        end
        @instance.on_load() if @instance.respond_to? 'on_load'

        @tsk = reactor.async do
          @method_status = {
            status: 'running',
            msg: nil
          }
          while (response = input_queue.dequeue) != END_APP

            # Quando o objeto roda em um container, gera muito 'nil' e não sei por que
            if response.nil?
              next
            end
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