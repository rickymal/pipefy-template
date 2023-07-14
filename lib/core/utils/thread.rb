module Lotus
  module Method
    module Thread 
      attr_reader :method_status
      def on_stop(*arg, **kwargs)

        # Matar a fibra para não ter tarefa em segundo plano

        # Esse 'if' é necessário pois se ocorrer algum erro na construção do objeto, o GC já realiza realizar o trigger do método 'on_stop'
        # sem nem mesmo a @tsk ter sido inicializada;

        if @tsk
          @tsk.stop()
          @pipe_thread.kill
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
        @pipe_thread.kill()
        # binding.pry
        @instance = nil
      end

      def create_pipe_task(pipe, reactor, input_queue, output_queue, services)
        
        @instance = pipe.new
        if @instance.respond_to? "_lotus_service_loading"
          @instance._lotus_service_loading(services)
        end
        isolated_queue_input = Queue.new()
        isolated_queue_output = Queue.new()
        
        @instance.on_load() if @instance.respond_to? "on_load"

        @pipe_thread = ::Thread.new do 
          while response = isolated_queue_input.pop()
            resp = @instance.call(response) do |yld|
              isolated_queue_output.push(yld)
            end

            # Libera o acesso para busca o próximo dado
            isolated_queue_output.push(nil)
          end
        end
        reactor.async do 
          @method_status = {
            status: 'running',
            msg: nil
          }
          while (response = input_queue.dequeue) != END_APP
            # Quando o objeto roda em um container, gera muito 'nil' e não sei pq
            if response.nil?
              next
            end
            isolated_queue_input.push(response)
            while data = isolated_queue_output.pop()
              output_queue.enqueue data
            end
          end
        end
      end
    end
  end
end