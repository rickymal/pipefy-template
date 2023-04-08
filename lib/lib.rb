require 'async/queue'

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

    
    class Application
        def initialize(path, env, pipe)
            binding.pry

        end

        def run()
        end
    end

    module Method
        class Flow
        end
    end

    module Activity
        class Pipe
            def next()

            end
        end
        class Container
            def initialize()
                @pipe_flow = QueuePathBuilder.new()
                @env = nil
                @pipe = []
            end

            def pipe(element, type, env)
                @pipe << env.new(element, type)
            end

            def compile()
                return Application.new(@pipe_flow, @env, @pipe)
            end
        end
    end

    module Env
        module Fiber
        end
    end
end
