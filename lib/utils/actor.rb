module Lotus
  module Method
    module Actor
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
    
    
          def create_pipe_task(pipe, reactor, input_queue, output_queue, service)
            
            @ractor_pool = 10.times.map do 
              Ractor.new do 
                r_instances = Ractor.receive()
    
                while (resp = Ractor.receive) != END_APP
                  instances = Array(r_instances)
                  
    
                  if instances.size() > 1
                    rr = instances.inject {|last, nxt| nxt.call last}
                  else
                    rr = instances[0].call resp
                  end
    
                  Ractor.yield rr
                end
              end
            end
    
            @ractor_pool.each do |ractor|
              # Danado para gerar erros, mas vamos tentar
              # ractor.send self.new(service), move: true
    
              # melhor não 
              ractor.send pipe.new(), move: true
            end
            
            cycle = @ractor_pool.cycle()
            @tsk = reactor.async do |tsk|
              while (response = input_queue.dequeue) != END_APP
                actor = cycle.next()
                tsk.async do 
                  actor.send(response)
                  output_queue.enqueue actor.take()
                end
              end
            end
    
          end
    end
end
end