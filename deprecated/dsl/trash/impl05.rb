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
            hfb = []
            while resp = @io.dequeue
                Async::Task.current.annotate "Input between first and second pipe"
                another_response = @inp.inject(resp) {|it, nxt| nxt.call it}
                hfb << another_response
                @fb.first(another_response)
                if hfb.size() == 10
                    @fb.second(hfb, :all)
                    hfb = []
                end
            end 
            
            # enviando remanescente
            @fb.second(hfb, :remains)
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
end

class Fb
    def first(data)
        puts "Terminou com #{data}"
    end

    def second(data, status)
        binding.pry
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