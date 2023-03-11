require_relative 'queue_path_builder.rb'
require_relative 'operators'
require 'async'

class PipeDSL
    attr_reader :last_queue
    include Operator
  
    def self.with(module_ctx, blk, services = [], extensions = {})
        path_builder = QueuePathBuilder.new
        _, input_queue = path_builder.next
    
        pipe_dsl = new(module_ctx, path_builder, services, extensions)
        blk.bind(pipe_dsl).call(pipe_dsl)
        return input_queue, pipe_dsl.last_queue
    end
  
    def initialize(ctx, path_builder, services, extensions)
        @path_builder = path_builder
        @module = ctx
        @reactor = Async::Task.current
    
        klass = Class.new do
            def initialize(dependencies)
            dependencies.each { |it| it.bind(self).call }
            end
        end
    
        pre_initializers = services.map { |it| it.instance_method('pre_init') }
        @services = services
        @extensions = extensions
        @initializers = services.map { |it| it.instance_method('init') }
    
        pre_initializers.each { |it| it.bind(klass).call }
    
        klass.include(ctx)
        @klass = klass
        @ctx = klass.new(@initializers)
    end
  
    def source(method)
        input_queue, output_queue = @path_builder.next
        @last_queue = output_queue
    
        @reactor.async do
            klass = @klass
            dependencies = @initializers
            extensions = @extensions
    
            ctx = klass.new(dependencies)

            extensions.each do |key, val|

                ctx.singleton_class.attr_accessor key

                if val.is_a? Class 
                    plugin = val.new(ctx)
                else
                    plugin = val
                end

                if plugin.respond_to? 'on_load'
                    plugin.on_load()
                end
                ctx.send("#{key}=", plugin)
            end
            
            method = ctx.method(method) rescue binding.pry
            while resp = input_queue.dequeue
                method.call(resp) do |data|
                    output_queue.enqueue(data)
                end
            end

        rescue Exception => error
            binding.pry
        end
    end
  
    def flow(methods)
        input_queue, output_queue = @path_builder.next
        @last_queue = output_queue
    
        @reactor.async do
            # super(input_queue, output_queue, methods, @klass, @initializers, @extensions)
            klass = @klass
            dependencies = @initializers
            extensions = @extensions
            ctx = klass.new(dependencies)
            extensions.each do |key, val|

                ctx.singleton_class.attr_accessor key

                if val.is_a? Class
                    plugin = val.new(ctx)
                else
                    plugin = val
                end

                if plugin.respond_to? 'on_load'
                    plugin.on_load()
                end
                ctx.send("#{key}=", plugin)
            end

            methods = methods.map {|it| ctx.method(it)}
            while resp = input_queue.dequeue
                output_queue.enqueue methods.inject(resp) {|last, nxt| nxt.call last}
            end
            output_queue.enqueue nil 
        end
    end

    def _using(input_queue, output_queue, methods, klass, action, services, extensions)


    end
  
    def actor(methods)
        input_queue, output_queue = @path_builder.next
        @last_queue = output_queue
        klass = @klass
        services = Ractor.make_shareable(@services)
        extensions = Ractor.make_shareable(@extensions)
    
        ractor = Ractor.new(Ractor.make_shareable(methods), klass, services, extensions) do |methods, klass, services, extensions|
    
            ctx = klass.new(services.map { |it| it.instance_method('init') })
    
            extensions.each do |key, val|
            ctx.singleton_class.attr_accessor key
            if val.is_a? Class
                plugin = val.new(ctx)
            else
                plugin = val
            end
    
            if val.respond_to? 'on_load'
                plugin.on_load()
            end
            
            ctx.send("#{key}=", plugin)
            end
    
            methods = methods.map { |it| ctx.method(it) }
            while resp = Ractor.receive
            rr = methods.inject(resp) { |last, nxt| nxt.call(last) }
            Ractor.yield(rr)
            end
        end
    
        @reactor.async do
            while resp = input_queue.dequeue
            ractor.send(resp)
            output_queue.enqueue(ractor.take)
            end
            output_queue.enqueue(nil)
        end
    end
end