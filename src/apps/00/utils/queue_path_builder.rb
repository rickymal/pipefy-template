require 'async'
require 'async/queue'

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