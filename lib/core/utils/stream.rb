module Lotus
  module Method
    module Stream 
      attr_reader :method_status
      def on_stop()

        # Matar a fibra para não ter tarefa em segundo plano

        # Esse 'if' é necessário pois se ocorrer algum erro na construção do objeto, o GC já realiza realizar o trigger do método 'on_stop'
        # sem nem mesmo a @tsk ter sido inicializada;
        
        if @tsk
          @tsk.stop()
        end

        # Liberando para o Garbagge Collector 
        @instance = nil
      end

      def on_error(exception = nil)
        # binding.pry
        @method_status = {
          status: 'error',
          msg: exception
        }
        @tsk.stop()
        # binding.pry
        @instance = nil
      end

      def create_pipe_task(pipe, reactor, input_queue, output_queue, services)
        
        @instance = pipe.new
        if @instance.respond_to? "_lotus_service_loading"
          @instance._lotus_service_loading(services)
        end
        @instance.on_load() if @instance.respond_to? "on_load"
        
        @tsk = reactor.async do 
          @method_status = {
            status: 'running',
            msg: nil
          }
          while (response = input_queue.dequeue) != END_APP

            # Quando o objeto roda em um container, gera muito 'nil' e não sei pq
            if response.nil?
              next
            end
            result_code = @instance.call(response) do |yld|
              output_queue.enqueue yld
            end
            if result_code == 0
              output_queue.enqueue END_APP
              break
            end
          end
        end
      end
    end
  end
end