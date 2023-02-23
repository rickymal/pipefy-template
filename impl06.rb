require_relative './impl04.1.rb'
require 'async'
require 'pry'
require 'concurrent'
require 'concurrent-edge'
require 'async'
require 'async/queue'
require 'pry-stack_explorer'

module DefaultWorker
    def get_source_queue()
        return Async::LimitedQueue.new 20
    end

    def get_flow_queue()
        return Async::LimitedQueue.new 20
    end
end

require 'concurrent'
require 'concurrent-edge'

class Env
    def initialize(procedures)
        @procedures = procedures
        @queue = Concurrent::Promises::Channel.new 10
    end

    def send_take(content)
        @procedures.inject(content) {|it, nxt| nxt.call it}
    end

end



module Schema
    include DefaultWorker

    def initialize(schema_i, schema_o, worker, fb)
        @inp = schema_i
        @out = schema_o

        @inp = Env.new schema_i
        @out = Env.new schema_o

        
        @fb = fb
        @worker = worker

        @ch = get_source_queue()
        @io = get_flow_queue()

        worker.async do 
            Async::Task.current.annotate "Input between source and first pipe"
            while resp = @ch.dequeue
                another_response = @inp.send_take(resp)
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


module Sequence
    def initialize(procedure, input, output, it, &blk)
        @input = input
        @output = output
        @procedure = procedure
        self.init()

        if !input.nil?
            it.async do 
                while resp = input.dequeue
                    another_response = nil
                    ctx = process(resp) do |data|
                        another_response = procedure.inject(data) {|it, nxt| nxt.call it} 
                    end

                    if ctx.nil?
                        next
                    end

                    if output.nil?
                        blk.call another_response
                    else
                        output.enqueue another_response                        
                    end
                end
            end
        end

    end

    def send(data)
        processed_data = @procedure.inject(data) {|it, nxt| nxt.call it}
        @output.enqueue(processed_data)
    end
end

class Darray
    include Sequence

    def init()
        @hfb = []
    end

    def process(data, &blk)
        @hfb << data
        puts "processando, atual #{@hfb.size()}"
        if @hfb.size() == 3
            blk.call @hfb
            @hfb = []
            return 0
        end

        return nil
    end
end

# Async::Task::current"
Async do |it|
    it.annotate "Principal"

    # Mockar pipeline que irão somar numeros
    procedures = Array.new(2) do
        next proc do |it| 
            puts "rodando #{it}"
            sleep 0.5
            if it.is_a? (Array)
                result = it.map do |it| 
                    if it.is_a? Array
                        next it.map {|it| it + 1}
                    end
                    next it + 1
                end
            else
                result = it + 1
            end
            next(result)
        end
    end

    b1 = Async::LimitedQueue.new 20
    b2 = Async::LimitedQueue.new 20

    s1 = Darray.new procedures, nil, b1, it
    s2 = Darray.new procedures, b1, b2, it
    s3 = Darray.new(procedures, b2, nil, it) do |itu| 
        puts "pi pi pi tchu"
        binding.pry
    end

    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
    s1.send 10
end
