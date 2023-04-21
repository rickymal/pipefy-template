
require 'async'
# -*- encoding: utf-8 -*-
require 'async/queue'
require_relative 'promise'

END_APP = :_enum_end_app

# Módulo principal Lotus
module Lotus
  # Módulo para implementação do padrão Singleton e carregamento de serviços
  module DefaultInitializer
    def load_services(services = {})
      services.each do |name, srv|
        self.singleton_class.attr_accessor name
        self.send("#{name}=", srv)
      end
    end
  end

  # Módulos para diferentes tipos de execução de atividades
  module Method
    # Módulo para execução sequencial de atividades
    module Flow
      def stop
        @task.stop
        @instance = nil
      end

      def handle_error(exception = nil)
        @instance = nil
      end

      def create_pipe_task(pipe, reactor, input_queue, output_queue, services)
        @input_queue = input_queue
        @instance = pipe.new
        @instance.load_services(services) if @instance.respond_to?(:load_services)

        @task = reactor.async do
          while (response = input_queue.dequeue) != END_APP
            begin
              resp = @instance.call(response)
            rescue CustomException => exception
              @ctx.throw_pipeline(exception)
            else
              output_queue.enqueue resp
            end
          end
        end
      end
    end

    # Módulo para execução em streaming de atividades
    module Stream
      def stop
        puts "Stopping application #{self}"
        @task.stop
        @instance = nil
      end

      def handle_error(exception = nil)
        @instance = nil
      end

      def create_pipe_task(pipe, reactor, input_queue, output_queue, services)
        @instance = pipe.new
        @instance.load_services(services) if @instance.respond_to?(:load_services)

        @task = reactor.async do
          while (response = input_queue.dequeue) != END_APP
            @instance.call(response) do |yielded_value|
              output_queue.enqueue yielded_value
            end
          end
        end
      end
    end

    # Módulo para execução em paralelo de atividades usando Ractors
    module Actor
      POOL_SIZE = 10

      def stop
        puts "Stopping application #{self}"
        @task.stop
        @instance = nil
      end

      def handle_error(exception = nil)
        @instance = nil
      end

      def create_pipe_task(pipe, reactor, input_queue, output_queue, services)
        @ractor_pool = POOL_SIZE.times.map do
          Ractor.new do
            r_instances = Ractor.receive

            while (resp = Ractor.receive) != END_APP
              instances = Array(r_instances)

              if instances.size > 1
                result = instances.inject { |last, nxt| nxt.call last }
              else
                result = instances[0].call resp
              end

              Ractor.yield result
            end
          end
        end

        @ractor_pool.each do |ractor|
          ractor.send pipe.new, move: true
        end

        cycle = @ractor_pool.cycle
        @task = reactor.async do |task|
          while (response = input_queue.dequeue) != END_APP
            actor = cycle.next
            task.async do
              actor.send(response)
              output_queue.enqueue actor.take
            end
          end
        end
      end
    end
  end
end

# Exceção personalizada para erros no processamento das atividades
class CustomException ; end
    

    class HelloWithBigDelay
      include Lotus::DefaultInitializer
      extend Lotus::Method::Flow
    
      def call(data = nil)
        sleep 1
        return 'Hello, world!'
      end
    end
    
    class HelloWithBigDelayAndError
      include Lotus::DefaultInitializer
      extend Lotus::Method::Flow
    
      def call(data = nil)
        sleep 1
        raise CustomException, "A custom error"
      end
    end
    
    class HelloWorld
      include Lotus::DefaultInitializer
      extend Lotus::Method::Flow
    
      def call(data = nil)
        return "Hello, world!"
      end
    end
    
    class Extract
      include Lotus::DefaultInitializer
      extend Lotus::Method::Stream
    
      def call(data = nil)
        data.times do |yielded_value|
          yield yielded_value
        end
      end
    end
    
    class Transform
      include Lotus::DefaultInitializer
      extend Lotus::Method::Actor
    
      def call(data = nil)
        res = "transforming: #{data}"
        return res
      end
    end
    
    class Load
      include Lotus::DefaultInitializer
      extend Lotus::Method::Flow
    
      def call(data = nil)
        return "data: #{data}"
      end
    end
    
    class PrintService
      def initialize(name)
        @name = name
      end
    
      def say_name
        @name
      end
    end
    
    class HelloWithServiceArgs
      include Lotus::DefaultInitializer
      extend Lotus::Method::Flow
    
      def call(data = nil)
        return "Hello, #{self.print_service.say_name}"
      end
    end
    
    class FeedBack
      include Lotus::DefaultInitializer
      extend Lotus::Method::Flow
    
      def call(data = nil)
      end
    end
    
    module Lotus
      class QueuePathBuilder
        attr_reader :queues
    
        def initialize
          @queues = [nil, nil]
          @path = build_path
        end
    
        def next
          @path.next
        end
    
        private
    
        def build_path
          Async::LimitedQueue.new(20).then do |input_queue|
            @queues[0] = input_queue
            Enumerator.new do |yielder|
              loop do
                output_queue = Async::LimitedQueue.new(20)
                @queues[1] = output_queue
                yielder << [input_queue, output_queue]
                input_queue = output_queue
              end
            end
          end
        end
      end
    
      module Activity
        class Pipe
          def next
          end
        end
    
        class Task
          def initialize(ctx, pipe, reactor, input_queue, output_queue, services)
            @ctx = ctx
            @pipe = pipe
            @reactor = reactor
            @input_queue = input_queue
            @output_queue = output_queue
            @services = services
            ObjectSpace.define_finalizer(self, self.class.finalize(self))
          end
    
          def self.finalize(obj)
            return lambda do |status|
              obj.stop
            end
          end
    
          def create_pipe_task
            create_pipe_task(@pipe, @reactor, @input_queue, @output_queue, @services)
          end
    
          def stop
            self.stop
          end
        end
    
        class Application
          def stop
            self.update_status 'stopping'
            @tasks.each(&:stop)
            self.update_status 'stopped'
          end
    
          def throw_pipeline(exception)
            self.update_status 'erroring'
            @tasks.each { |task| task.handle_error(exception) if task.respond_to? 'handle_error' }
            self.update_status 'errored'
        end

        def update_status(status)
            @status = status
          end
        
          def status
            @status
          end
        end
    end
end

# uso

Async do |task|
    app = Lotus::Activity::Application.new
    app.extend Lotus::Activity::Pipe
    app.extend Lotus::QueuePathBuilder
    
    tasks = [
    HelloWithBigDelay,
    HelloWithBigDelayAndError,
    HelloWorld,
    Extract,
    Transform,
    Load,
    HelloWithServiceArgs,
    FeedBack
    ]
    
    services = {
    print_service: PrintService.new('John Doe')
    }
    
    tasks.each do |task_pipe|
    input_queue, output_queue = app.next
    task.async do
    task_pipe.create_pipe_task(input_queue, output_queue, services)
    end
    end
    
    app.queues.first.enqueue(5)
    app.queues.last.enqueue(Lotus::END_APP)
    
    result = []
    while (response = app.queues.last.dequeue) != Lotus::END_APP
    result << response
    end
    
    puts "Results: #{result.inspect}"
    app.stop
    end
    