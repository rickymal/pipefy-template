require 'async'
require 'async/queue'
require 'pry'
# Somente o 'source' e o 'flow', nada de 'batch'!
# Keep it simple
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



module Operator
  def flow(input_queue, output_queue, methods, klass, dependencies, extensions)
    
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

  def source(input_queue, output_queue, method, klass, dependencies, extensions)

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
    
    
    method = ctx.method(method)
    while resp = input_queue.dequeue
      method.call(resp) do |data|
        output_queue.enqueue(data)
      end
    end

    output_queue.enqueue nil
  end
end

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

  def source(method_name)
    input_queue, output_queue = @path_builder.next
    @last_queue = output_queue

    @reactor.async do
      super(input_queue, output_queue, method_name, @klass, @initializers, @extensions)
    rescue Exception => error
      binding.pry
    end
  end

  def flow(methods)
    input_queue, output_queue = @path_builder.next
    @last_queue = output_queue

    @reactor.async do
      super(input_queue, output_queue, methods, @klass, @initializers, @extensions)
    end
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

  class YAMLLoader
    def initialize(ctx = nil)
    end

    def pre
      'oooooi'
    end
  end
end

class Pipefy
  def initialize(mdl, drawer:, services:, extensions:)
    

    # podemos definir a ordem no proprio modulo
    if drawer.nil?
      drawer = mdl
    end

    @mdl = mdl
    @drawer = drawer
    @services = services
    @extensions = extensions
  end
  
  def build_pipeline()
    drawer = @drawer.instance_method 'draw_pipeline'
    return Dsl.with @mdl, drawer, @services, @extensions
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

pipe = Pipefy.new(
  App,
  drawer: Example,
  services: [Operator::SPDCommons],
  extensions: {
    yml: Operator::YAMLLoader.new()
  }
)
Async do |it|


  ctxi, ctxo = pipe.build_pipeline()
  ctxi.enqueue 100
  sleep 1
  puts ctxo.dequeue
  binding.pry

end
