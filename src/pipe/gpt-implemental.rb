require 'async'
require 'async/queue'
require 'pry'
# Somente o 'source' e o 'flow', nada de 'batch'!
# Keep it simple
class QueuePathBuilder
  def initialize()
    @mtx = Mutex.new()
    @path = Enumerator.new do |yld|
      q1 = Async::LimitedQueue.new 20
      loop do
        @mtx.synchronize do
          q2 = Async::LimitedQueue.new 20
          yld << [q1, q2]
          q1 = q2
        end
      end
    end
  end

  def next()
    @path.next()
  end
end
$queues = []


class PipeDSL

  # @@queue_builder = (1..).lazy.map { Async::LimitedQueue.new 10 }.each_cons(2)
  
  def self.with(module_ctx, &blk)
    path_builder = QueuePathBuilder.new
    _, q1 = path_builder.next()

    pipe_dsl = new module_ctx, path_builder
    pipe_dsl.instance_eval(&blk) 

    sleep 1
    return q1
  end

  def initialize ctx, path_builder
    # ElasticObject.create_klass ctx
    @path_builder = path_builder
    @module = ctx
    # @reactor = reactor = Async::Reactor.new
    @reactor = Async::Task.current
    klass = Class.new
    klass.include ctx
    @ctx = klass.new()
  end

  def source(method_name)
    q1, q2 = @path_builder.next
    method = @ctx.method(method_name)
    @reactor.async do |task|
      while resp = q1.dequeue
        method.call resp do |data|
          q2.enqueue(data)
        end    
      end
      q2.enqueue nil
    end
  end

  def flow(methods)
    q1, q2 = @path_builder.next
    methods = methods.map {|it| @ctx.method(it)}
    @reactor.async do
      while resp = q1.dequeue
        q2.enqueue methods.inject(resp) {|last, nxt| nxt.call last}
      end
      q2.enqueue nil
    end
  end
end

class Dsl < PipeDSL
end

module App
  def load_enterprises(input = nil)
    yield "data1"
    yield "data2"
    yield "data3"
  end

  def load_stablisments(data)
    yield "data4 with #{data}"
    yield "data5 with #{data}"
    yield "data6 with #{data}"
  end

  def load_partners(data)
    yield "data7, #{data}"
    yield "data8, #{data}"
    yield "data9, #{data}"
  end

  def t1(data)
    puts "processando t1: #{data}"
    return data
  end
  
  def t2(data)
    puts "processando t2: #{data}"
    return data
  end
  
  def t3(data)
    puts "processando t3: #{data}"
    return data
  end
end



Async do
  ctx = Dsl.with App do
    source 'load_enterprises'
    source 'load_stablisments'
    source 'load_partners'
    flow ['t1', 't2', 't3']
  end  
  ctx.enqueue 100

  # Para finalizar
  ctx.enqueue nil
  sleep 5
  puts 'fim'.center 80, '-'
end

# Pipeline.with [App] do
#   using Default do 
#     source 'load_enterprises'
#     source 'load_stablisments'
#     source 'load_partners'
#     flow ['t1','t2','t3']
#   end

#   using Actor do 
#     flow ['t4','t5','t6']
#   end
# end