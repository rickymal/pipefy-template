require_relative './impl04.1.rb'
require 'async'
require 'pry'
require 'concurrent'
require 'concurrent-edge'
require 'async'
require 'async/queue'
require 'pry-stack_explorer'

module EnvSwitch
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
    include EnvSwitch

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

class Env
    def initialize(sequence)
        @sequence = sequence
    end

    def send_take(data)
        @sequence.inject(data) do { |it,nxt| nxt.call it }
    end
end

class SrcEnv
    def initialize(sequence)
        @sequence = sequence
    end

    def send_take(data)
        @sequence.inject(data) do { |it,nxt| nxt.call it }
    end
end

class RemoteEnv
    def initialize(sequence)

        # Suponod que de alguma forma eu passei pro outro lado
        @ractor = Ractor.new() do
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

            while resp = Ractor.receive()
                Ractor.yield(procedures.inject(resp) {|it, nxt| nxt.call it})
            end
        end
    end

    def send_take(data)
        @ractor.send(data)
        return @ractor.take()
    end
end


module Sequence
    def initialize(procedure, input, output, it, &blk)
        @input = input
        @output = output
        @procedure = procedure
        self.init()
        @env = define_worker().new procedure

        if !input.nil?
            it.async do 

                # Puxa o dado da fonte!
                while resp = input.dequeue
                    another_response = nil

                    # Realiza um pre-processando para saber se vai adiante. Caso sim, é passado para o 'data'
                    process(resp) do |data|

                        # Método send_take pode ser do tipo 'source' ou simplesmente realizar um 'return'
                        another_response = @env.send_take(data) do |thr|
                            another_response = thr

                            # Caso não tenha obtido retorno 
                            if another_response.nil?
                                next
                            end
        
                            # Envia para o próximo pipe ou simplesmente retorna tudo logo
                            if output.nil?
                                blk.call another_response
                            else
                                output.enqueue another_response                        
                            end
                        end

                    end
                end

                if false
                    # Jeito mais simples, porém que não permite o uso de sourcing
                    # Puxa o dado da fonte!
                    while resp = input.dequeue
                        another_response = nil
    
                        if data = process(resp)
                            if thr = @env.send_take(data)
                                if thr.nil?
                                    next
                                end
    
                                if output.nil?
                                    blk.call thr
                                else
                                    output.enqueue thr
                                end
                            end
                        end
                    end
                end
            end
        end

    end

    def send(data)
        processed_data = @env.send_take(data) do |thr|
            @output.enqueue(thr)
        end
        # processed_data = @procedure.inject(data) {|it, nxt| nxt.call it}
    end
end

module Worker
    def define_worker()
        # return RemoteEnv
        # return Env
        return SrcEnv
    end
end

class Darray
    include Sequence
    include Worker 

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
    procedures = Array.new(1) do
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

# raise Exception, "Assistir: https://semana.javascriptexpert.com.br/aquecimento"



# Garantir que posso passa 'sourcers' nos procedures
# Garantir que o Ractor consiga rodar de forma assíncrona (sem precisar de um retorno)

# Async::Task::current"
Async do |it|
    it.annotate "Principal"
    # Mockar pipeline que irão somar numeros
    procedures = Array.new(2) do
        next proc do |it| 
            (it..(it+10)).each do |ctx|
                yield ctx
            end
        end
    end

    b1 = Async::LimitedQueue.new 20
    b2 = Async::LimitedQueue.new 20

    s1 = Darray.new procedures, nil, b1, it
    s2 = Darray.new procedures, b1, b2, it
    s3 = Darray.new(procedures, b2, nil, it) do |itu| 
        puts "pi pi pi tchu"
        
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
raise Exception, 'Fazer agora um sequencia de sourers'

# Não dá para permitir com que eu tenha flexibilidade sem prejudicar a construção da classe
# Preciso retirar a flexibilidade aqui

# O bloco irá ser executado na instancia do objeto ETLBatch
ETLBatch = Dashboard.new [Program] do |elastic_klass|

    # Criando de forma dinâmica!
    self.instance_methods(false).each do |method|
        if method.to_s.include? ("src")
            elastic_klass.source self.method(method)
        elsif method.to_s.include? ("t_")
            elastic_klass.flow self.method(method)
        else
            # just continue
        end
    end

    # Criando de forma estática
    elastic_klass
        .source self.method('extract')
        .flow self.method('transform1')
        .raw self.method('transform2') do |queue|
            @hfb = Darray.new 10, 10 do |batch|
                queue.enqueue batch
            end
        end
        .flow self.method('dispatch')
end