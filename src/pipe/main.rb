require './src/apps/main.rb'
require './src/core/dsl.rb'
require 'pry-stack_explorer'
require 'async'
require 'async/queue'


# Obtendo os métodos em partes

load_enterprises = App.instance_method 'load_enterprises'
load_stablisments = App.instance_method 'load_stablisments'
load_partners = App.instance_method 'load_partners'
run = App.instance_method 'run'
dispatch_data = App.instance_method 'dispatch_data'
dispatch_in_ractor1 = App.instance_method 'dispatch_in_ractor1'
dispatch_in_ractor2 = App.instance_method 'dispatch_in_ractor2'

q1 = Async::LimitedQueue.new 10
q2 = Async::LimitedQueue.new 10
q3 = Async::LimitedQueue.new 10
q4 = Async::LimitedQueue.new 10

module Operator
    module Batch
        def queue(queue)
            @queue = queue
            @hfb = Array.new()
        end

        def pre_call()
        end

        def post_call()
            if @hfb.size() == 5
                @queue.enqueue @hfb
                @hfb.clear
            end
        end
    end
end


# Aqui teremos a injeção lambda!
class Context
    def self.partial_load(mod)
        clone = self.dup()
        clone.include mod
        clone.new()
    end
end

ctx = Context.new()
Async do |it|
    # Isso é o 'run'
    it.async do 
        load_enterprises.bind(ctx).call 100 do |result|
            # puts "Valor #{result}"
            q1.enqueue result
        end
    end

    it.async do
        while resp = q1.dequeue
            load_stablisments.bind(ctx).call resp do |result|
                q2.enqueue(result)
            end
        end
    end


    it.async do
        while resp = q2.dequeue
            load_partners.bind(ctx).call resp do |result|
                puts "Mais que lendo: #{result}"
                q3.enqueue(result)
            end
        end
    end

    # Injetando contexto
    ctx = Context.partial_load Operator::Batch
    it.async do
        ctx.queue(q4)
        while resp = q3.dequeue
            ctx.pre_call()
            run.bind(ctx).call resp
            ctx.post_call()
        end
    end

    it.async do
        while resp = q4.dequeue
            dispatch_data.bind(ctx).call resp
        end
    end
end
