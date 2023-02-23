require_relative './impl04.1.rb'
require 'async'
require 'pry'
require 'concurrent'
require 'concurrent-edge'
require 'async'
require 'async/queue'
require 'pry-stack_explorer'

module Schema
    def initialize(schema_i, schema_o, worker, fb)
        @inp = schema_i
        @out = schema_o
        @wor = worker
        @fb = fb
        @worker = worker

        @ch = Async::LimitedQueue.new(20)
        @io = Async::LimitedQueue.new(20)

        worker.async do 
            Async::Task.current.annotate "Input between source and first pipe"
            while resp = @ch.dequeue
                another_response = @inp.inject(resp) {|it, nxt| nxt.call it}
                @io.enqueue another_response
            end  

            @io.enqueue nil
        end

        worker.async do 
            if self.respond_to? 'init'
                self.init()
            end
            
            while resp = @io.dequeue
                Async::Task.current.annotate "Input between first and second pipe"
                another_response = @inp.inject(resp) {|it, nxt| nxt.call it}

                @fb.on_receive(another_response)

                

                self.dispatch() do |data|
                    @fb.on_finish(data, :all)
                    # Aqui eu tenho que passar para o próximo pipe 
                end
            end 
            
            # enviando remanescente
            @fb.on_finish(data, :remains)
        end

    end

    def send(data)
        @worker.async do
            @ch.enqueue data
        end
    end
end

class Darray
    include Schema

    def init()
        @hfb = []
    end

    def dispatch(data, &blk)
        @hfb << another_response
        if @hfb.size() > 10
            blk.call @hfb
            @hfb = []
        end
    end
end

class Fb
    def on_receive(data)
        puts "Terminou com #{data}"
    end

    def on_finish(data, status)

        puts "Terminou valendo com #{data} com status #{status}"
    end

end

# Async::Task::current"
Async do |it|
    it.annotate "Principal"

    # Mockar pipeline que irão somar numeros
    procedures = Array.new(5) do
        next proc do |it| 
            puts "rodando #{it}"
            sleep 0.5
            next(it + 1)
        end
    end
    iom1 = Darray.new(procedures, procedures, it, Fb.new())
    
    Array(1..26).each do |itu|
        iom1.send itu
    end
    iom1.send nil
end