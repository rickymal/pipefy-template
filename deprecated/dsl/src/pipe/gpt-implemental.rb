require 'async'
require 'async/queue'
require 'pry'
# Somente o 'source' e o 'flow', nada de 'batch'!
# Keep it simple
class QueuePathBuilder
  attr_reader :queues
  def initialize()
    @mtx = Mutex.new()
    @queues = [nil, nil]
    @path = Enumerator.new do |yld|
      q1 = Async::LimitedQueue.new 20
      @queues[0] = q1
      loop do
        @mtx.synchronize do
          q2 = Async::LimitedQueue.new 20
          @queues[1] = q2
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


module Operator
  def flow(q1, q2, methods, klass, dependencies)
    ctx = klass.new(dependencies)
    methods = methods.map {|it| ctx.method(it)}
    while resp = q1.dequeue
      q2.enqueue methods.inject(resp) {|last, nxt| nxt.call last}
    end
    q2.enqueue nil 
  end

  def source(q1, q2, method, klass, dependencies)
    ctx = klass.new(dependencies)
    method = ctx.method(method)
    while resp = q1.dequeue
      method.call(resp) do |data|
        q2.enqueue(data)
      end
    end

    q2.enqueue nil
  end
end

class PipeDSL
  attr_reader :last_queue
  include Operator

  # @@queue_builder = (1..).lazy.map { Async::LimitedQueue.new 10 }.each_cons(2)
  
  def self.with(module_ctx, blk, services = nil)

    path_builder = QueuePathBuilder.new
    _, q1 = path_builder.next()

    pipe_dsl = new module_ctx, path_builder, services
    blk.bind(pipe_dsl).call pipe_dsl
    # pipe_dsl.instance_eval(&blk) 

    return q1 , pipe_dsl.last_queue
  end

  class ElasticObject

    def initialize(dependencies)
      dependencies.each do |it|
        it.bind(self).call()
      end
    end
  end

  def initialize ctx, path_builder, services
    # ElasticObject.create_klass ctx
    
    @path_builder = path_builder
    @module = ctx
    @reactor = Async::Task.current

    # Gerador de contexto 
    klass = ElasticObject.dup()

    # obtendo os pre initializadores
    pre_initializers = services.map {|it| it.instance_method 'pre_init'}
    @services = services
    @initializers = services.map {|it| it.instance_method 'init'}
    # post_initializers = services.map {|it| it.instance_method 'post_init'}

    pre_initializers.each do |it|
      it.bind(klass).call()
    end

    # klass.initializers = initializers
    # klass.post_initializers = post_initializers
    klass.include ctx
    @klass = klass
    
    @ctx = klass.new(@initializers)
    
  end

  def source(method_name)
    q1, q2 = @path_builder.next
    @last_queue = q2
    @reactor.async do |task|
      super(q1, q2, method_name, @klass, @initializers) 
    rescue Exception => error 
       
    end
  end

  def flow(methods)
    q1, q2 = @path_builder.next
    @last_queue = q2

    @reactor.async do
      super(q1, q2, methods, @klass, @initializers)
    end
  end

  def actor(methods)
    q1, q2 = @path_builder.next
    @last_queue = q2
    klass = @klass
    
    services = Ractor.make_shareable @services
    ractor = Ractor.new(Ractor.make_shareable(methods), klass,  services) do |methods, klass, services|
      ctx = klass.new(services.map {|it| it.instance_method('init')})
      methods = methods.map {|it| ctx.method(it)}
      while resp = Ractor.receive()
        rr = methods.inject(resp) {|last, nxt| nxt.call last}
        Ractor.yield rr
      end
    end
    @reactor.async do
      while resp = q1.dequeue
        ractor.send resp
        q2.enqueue ractor.take()
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
    # yield "data2"
    # yield "data3"
  end

  def load_stablisments(data)
    yield "data4 with #{data}"
    # yield "data5 with #{data}"
    # yield "data6 with #{data}"
  end

  def load_partners(data)
    yield "data7, #{data}"
    # yield "data8, #{data}"
    # yield "data9, #{data}"
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

  def t4(data)
    puts "processando t4: #{data}"
    return data
  end
  
  def t5(data)
    puts "processando t5: #{data}"
    return data
  end
  
  def t6(data)
    puts "processando t6: #{data}"
    return data
  end
end


module Operator
  module SPDCommons
    def pre_init()
      puts "PRE INICIALIZANDO!"
    end
    
    def init()
      puts "INICIALIZANDO!"
    end

    def post_init()
    end
  end
end

class Pipefy
  def initialize(mdl, drawer:, services:)
    

    # podemos definir a ordem no proprio modulo
    if drawer.nil? && 
      drawer = mdl
    end

    @mdl = mdl
    @drawer = drawer
    @services = services
  end
  
  def build_pipeline()
    drawer = @drawer.instance_method 'draw_pipeline'
    return Dsl.with @mdl, drawer, @services
  end
end


module Example
  def draw_pipeline(dsl)
    source 'load_enterprises'
    source 'load_stablisments'
    source 'load_partners'
    flow ['t1', 't2', 't3']
    actor ['t4', 't5', 't6']
  end
end

Async do |it|

  pipe = Pipefy.new(
    App,
    drawer: Example,
    services: [Operator::SPDCommons],
  )

  ctxi, ctxo = pipe.build_pipeline()
  

  # [OLD]
  # ctx, ctxo = Dsl.with App do
  #   source 'load_enterprises'
  #   source 'load_stablisments'
  #   source 'load_partners'
  #   flow ['t1', 't2', 't3']
  #   actor ['t4', 't5', 't6']
  # end  

  # ctxi =ctx
  # ctxi.enqueue 100
  # sleep 5

  # it.async do 
  #   while resp = ctxo.dequeue()
  #     puts "[PRC] #{resp}"
  #   end
  # end

  # # Para finalizar
  # ctx.enqueue nil
  # sleep 5
  # puts 'fim'.center 80, '-'
end
