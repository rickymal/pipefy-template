require 'async/queue'
require_relative 'promise'

END_APP = :_enum_end_app

module Lotus
  module DefaultInitializer
    def initialize(service = {})
        
      service.each do |name, srv|
        self.singleton_class.attr_accessor name
        self.send("#{name}=", srv)
      end

    end
  end


  module Method
    module Flow
      
      

      def create_pipe_task(reactor, input_queue, output_queue, service)
        instance = self.new(service) rescue binding.pry
        reactor.async do
          while (response = input_queue.dequeue) != END_APP
            output_queue.enqueue instance.call(response)
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
    
    # Tem que ser uma classe, pois preciso passar uma instância.
    module Actor
      def create_pipe_task(reactor, input_queue, output_queue, service)
        
        ractor_pool = 10.times.map do 
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

        ractor_pool.each do |ractor|
          # Danado para gerar erros, mas vamos tentar
          # ractor.send self.new(service), move: true

          # melhor não 
          ractor.send self.new(), move: true
        end
        
        cycle = ractor_pool.cycle()
        reactor.async do |tsk|
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

class CustomException < Exception ; end

class HelloWithBigDelay
  include Lotus::DefaultInitializer
  extend Lotus::Method::Flow

  def call(data = nil)
    sleep 10
    return 'Hello, world!'
  end
end

class HelloWithBigDelayAndError
  include Lotus::DefaultInitializer
  extend Lotus::Method::Flow

  def call(data = nil)
    sleep 10
    raise CustomException, "Um erro personalizado"
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
    data.times do |yld|
      yield yld
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

  def say_name()
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

    class Application
      def initialize(activities, services, &blk)
        pipe_flow = QueuePathBuilder.new
        @activities = activities
        
        if self.respond_to? :reactor 
          reactor = self.reactor()
        else
          reactor = Async::Task.current()
        end
        
        input_queue, output_queue = pipe_flow.next
        @input_queue = input_queue

        @activities.each do |activity|
          
          pipe, service = activity
          
          pipe_instance = pipe.create_pipe_task(reactor, input_queue, output_queue, service) rescue binding.pry
          input_queue, output_queue = pipe_flow.next
          @output_queue = input_queue
        end

        if blk
          Async do
            while (response = @output_queue.dequeue) != END_APP
              
              blk.call response
            end
          end
        end
      end

      def call(data_in = nil)
        @input_queue.enqueue data_in
      end
    end

    class Container
      attr_accessor :name
      @@applications = {}


      def self.info(*informations)
        @@applications
      end

      def initialize(app = Lotus::Activity::Application)
        @app = app
        @activities = []
      end

      def pipefy(element, **services)
        @activities << [element, services]
      end

      # def new(services = [], &blk)
      #   @app.new(@activities, services, &blk)
      # end

      def new(services = [], &blk)
        # Atualize @@applications cada vez que uma nova aplicação for criada
        app_instance = @app.new(@activities, services, &blk)
        app_name = @name.dup

        if @@applications[app_name].nil?
          @@applications[app_name] = {
            'applications' => {}
          }
        end

        app_instance_id = "#{app_name} <##{@@applications[app_name]['applications'].size + 1}>"
        @@applications[app_name]['applications'][app_instance_id] = 'running'

        # Adicione um método update_status na instância da aplicação
        app_instance.define_singleton_method(:update_status) do |status|
          @@applications[app_name]['applications'][app_instance_id] = status
        end

        return app_instance
      end
    end
  end
end
