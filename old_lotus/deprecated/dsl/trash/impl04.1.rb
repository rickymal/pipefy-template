
# https://github.com/socketry/async-process
# https://github.com/socketry/async-container

require 'pry-stack_explorer'
require 'async'

require 'async'

# class Array
#   def async_inject(initial_value, &block)
#     Async do
#       result = initial_value

#       tasks = each.map do |item|
#         task = Async do
#           result = yield result, item
#         end

#         task.wait
#       end

#       tasks.map(&:wait)

#       result
#     end
#   end
# end


# Async do
#   result = [10,20,30,40,50].async_inject(0) do |sum, num|
#     Async do
#       sleep 1
#       sum + num
#     end
#   end

#   puts result # Output: 150 (after 5 seconds)
# end.wait


module AsyncEnumerator
    refine Enumerator do 
        def async_inject(initial_value, &block)
            Async do
                result = initial_value
            
                tasks = each.map do |item|
                    task = Async do
                    result = yield result, item
                    end
            
                    task.wait
                end
            
                tasks.map(&:wait)
                result
            end
        end
    end

    refine Array do
        def inject_envs(initial_val)
            
            self.each do |nenv|

                initial_val = nenv.call initial_val
                if nenv.next_env.env_status == :closed
                    break
                end
                
            end


            # if self.size() > 1
            #     iterator = self.each_cons(2)
            #     last_env, next_env = iterator.next()
            # elsif self.size() == 1
            #     iterator = [*self, nil].each_cons(2)
            #     last_env, next_env = iterator.next()
            # end

            # loop do 
            #     resp = last_env.call initial_val
            #     if next_env.status == :closed
            #         break
            #     end

            #     last_env, next_env = iterator.next()
            #     initial_val = resp

            # end 
        end
    end
end

class Batch
    def initialize(inventory, batch)
        @inventory = Array.new(inventory, [])
        @batch = batch
        @idx = 0
    end

    def dispatch_data(batch)
        @next_pipe.allow_send()
    end

    def <<(val)
        @inventory[@idx] << val

        if @inventory[@idx].size() == 10
            
            @idx += 1
            @nenv.next_env.env_status = :allow_send
        end
    end

    def inject_enviroment(klass, instance, cmethod, nenv)

        instance.send("set_#{cmethod}", self)
        @cmethod = cmethod
        @instance = instance
        @nenv = nenv
    end

    def data_flow(next_enviroment)
        @env = next_enviroment
    end

    def call(data)
        @instance.send(@cmethod, data) rescue 
    end
end

class Lambda
    def self.from_composition(composition)
        # Não era para ser assim, por hora apenas para 'mockar' a classe que será gerada futuramente
        klass = Class.new
        composition.each {|it| klass.include it}
        # composition.each {|it| klass.autoload it}
        return klass
    end
end

Pipe = Struct.new "Pipe", :method
Engine = Struct.new "Engine", :engine, :method, :eargs, :ekwargs

class CoreDrawer
    using AsyncEnumerator
    attr_reader :sequence, :next_env

    class Environment
        attr_accessor :env_status, :next_env

        def initialize(pipesequence)
            @pipesequence = pipesequence
            @next_env = nil
            self.env_status = :closed
        end

        def inject_as_sequence(environment)
            @next_env = environment
        end

        # cria um pipesequence que possui métodos 'call'
        def compile(klass, instance)
            @compiled_sequence = @pipesequence.map do |seq|
                if seq.is_a? Struct::Pipe
                    next instance.method(seq.method())                    
                end

                if seq.is_a? Struct::Engine
                    engine = seq.engine.new(10, 10)
                    engine.inject_enviroment(klass, instance, seq.method(), self) rescue 
                    next engine
                end
            end
        end

        def call(data)
            data = @compiled_sequence.inject(data) {|it, nxt| nxt.call it }
        end
    end

    def flow(method)
        @nib << @pipe.new(method)
    end

    def to(engine, method)

        @nib << @engine.new(engine, method, @template) rescue 
        next_env = Environment.new(@nib)
        last_env = @sequence.last()

        # Estrutura em cadeia
        if last_env.is_a? Environment
            last_env.inject_as_sequence(next_env)
        end

        @sequence << next_env
        @nib = Array.new()
    end

    def initialize()
        @pipe = Pipe
        @sequence = Array.new()
        @engine = Engine
        @nib = Array.new()
    end

    def self.draw(template = nil, &drawer)
        if template.nil?
            klass = self
        else
            klass = Lambda.from_composition template
        end
        core_drawer = self.new()
        drawer.call core_drawer

        # Implementações
        instance = klass.new()
        
        # Compile all
        core_drawer.sequence.each {|it| it.compile(klass, instance)}

        klass.define_method :run do |initial_val|
            core_drawer.sequence.inject_envs(initial_val) {|it, nxt| nxt.call it}
        end

        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)
        klass.new.run(10)

    end
end

