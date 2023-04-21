require "async"
require "pry"

END_APP = :_enum_end_app

module Lotus
  module DefaultInitializer
    macro included
      def _lotus_service_loading(service = {} of Symbol => UnboundProc)
        {% for name, srv in service %}
          @[Setter]
          def {{name.id}}=(@{{name.id}} : typeof({{srv}})); end

          @[Getter]
          def {{name.id}}; @{{name.id}}; end
        {% end %}
      end
    end
  end

  module Method
    module Flow
      def on_stop
        puts "Parando aplicação #{self}"
        @tsk.try &.stop
        @instance = nil
      end

      def on_error
        @tsk.try &.stop
        @instance = nil
      end

      def create_pipe_task(pipe : Pipe, reactor, input_queue, output_queue, services)
        @instance = pipe.new
        @instance._lotus_service_loading(services) if @instance.responds_to?(:_lotus_service_loading)
        
        @tsk = reactor.async do
          while (response = input_queue.dequeue) != END_APP
            begin
              resp = @instance.call(response)
            rescue CustomException => exception
              self.update_status "oops!"
              self.on_error
              self.update_status "error"
              binding.pry
            else
              output_queue.enqueue resp
            end
          end
        end
      end
    end

    module Stream
      def create_pipe_task(reactor, input_queue, output_queue, service)
        instance = self.new(service)
        reactor.async do
          while (response = input_queue.dequeue) != END_APP
            instance.call(response) do |yld|
              output_queue.enqueue yld
            end
          end
        end
      end
    end

    module Actor
      def create_pipe_task(reactor, input_queue, output_queue, service)
        ractor_pool = 10.times.map do
          Ractor.new do
            r_instances = Ractor.receive

            while (resp = Ractor.receive) != END_APP
              instances = Array(r_instances)

              if instances.size > 1
                rr = instances.inject { |last, nxt| nxt.call last }
              else
                rr = instances[0].call resp
              end

              Ractor.yield rr
            end
          end
        end

        ractor_pool.each do |ractor|
          ractor.send self.new, move: true
        end

        cycle = ractor_pool.cycle
        reactor.async do |tsk|
          while (response = input_queue.dequeue) != END_APP
            actor = cycle.next
            tsk.async do
              actor.send(response)
              output_queue.enqueue actor.take
            end
          end
        end
      end
    end
  end
end

class CustomException < Exception; end

class HelloWithBigDelay
  include Lotus::DefaultInitializer
  extend Lotus::Method::Flow

  def call(data = nil)
    sleep 10
    "Hello, world!"
  end
end

# Restante das classes...

module Lotus
  class QueuePathBuilder
    getter queues

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
            yielder << {input: input_queue, output: output_queue}
            input_queue = output_queue
          end
        end
      end
    end
  end

  module Activity
    abstract class Pipe
      abstract def call(data : _)
    end

    class Task
      def initialize(@pipe : Pipe, @reactor, @input_queue, @output_queue, @services)
        at_exit do
          stop
        end
      end

      def stop
        on_stop
      end

      include Lotus::Method::Flow
    end

    class Application
      def stop
        update_status "stopping"
        @tasks.each &.stop
        update_status "stopped"
      end

      def initialize(@activities, global_services, &@blk : _ -> _)
        pipe_flow = QueuePathBuilder.new
        @tasks = [] of Task

        input_queue, output_queue = pipe_flow.next, pipe_flow.next["output"]
        @input_queue = input_queue

        @activities.each do |activity|
          pipe, executor, services = activity
          task = Task.new(pipe, @reactor, input_queue, output_queue, services)
          task.extend executor
          task.create_pipe_task

          @tasks << task
          input_queue, output_queue = pipe_flow.next, pipe_flow.next["output"]
        end

        if @blk
          Async do
            while (response = output_queue.dequeue) != END_APP
              @blk.call response
            end
          end
        end
      end

      def call(data_in = nil)
        @input_queue.enqueue data_in
      end
    end

    class Container
      property! name : String
      @@applications = {} of String => Hash(String, String)

      def self.info(*informations)
        @@applications
      end

      def initialize(@app = Lotus::Activity::Application)
        @activities = [] of Tuple(Pipe, Module, Hash(Symbol, UnboundProc))
      end

      def pipefy(element : Pipe, executor : Module = Lotus::Method::Flow, **services)
        @activities << {element, executor, services}
      end

      def new(services = {} of Symbol => UnboundProc, &blk)
        app_instance = @app.new(@activities, services, &blk)
        app_name = @name.dup

        @@applications[app_name] ||= {"applications" => {} of String => String}
        app_instance_id = "#{app_name} <##{@@applications[app_name]["applications"].size + 1}>"
        @@applications[app_name]["applications"][app_instance_id] = "running"

        app_instance.define_singleton_method(:update_status) do |status|
          @@applications[app_name]["applications"][app_instance_id] = status
        end

        app_instance
      end
    end
  end
end
