
# ruby -W0 pipefy.rb  to 'run'
require 'async'
require 'async/queue'
require 'pry'
# Somente o 'source' e o 'flow', nada de 'batch'!
# Keep it simple

class PipefyConfig
  attr_accessor :ractor_count, :queue_size, :batch_size

  def initialize(ractor_count: nil, queue_size: 20, batch_size: 1)
    @ractor_count = ractor_count || default_ractor_count
    @queue_size = queue_size
    @batch_size = batch_size
  end

  private

  def default_ractor_count
    [1, Ractor.count - 1].max
  end
end

class QueuePathBuilder
  def initialize(config)
    @config = config
    @queues = [nil, nil]
    @path = build_path
  end

  private

  def build_path
    Async::LimitedQueue.new(@config.queue_size).then do |input_queue|
      @queues[0] = input_queue
      Enumerator.new do |yielder|
        loop do
          output_queue = Async::LimitedQueue.new(@config.queue_size)
          @queues[1] = output_queue
          yielder << [input_queue, output_queue]
          input_queue = output_queue
        end
      end
    end
  end
end

class QueuePathBuilder
  attr_reader :queues

  def initialize(config)
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
  def create_context(klass, dependencies, extensions)
    ctx = klass.new(dependencies)

    extensions.each do |key, val|
      ctx.singleton_class.attr_accessor key rescue binding.pry
      plugin = val.is_a?(Class) ? val.new(ctx) : val
      plugin.on_load() if plugin.respond_to?('on_load')
      ctx.send("#{key}=", plugin)
    end

    ctx
  end

  def flow(input_queue, output_queue, methods, klass, dependencies, extensions)
    ctx = create_context(klass, dependencies, extensions)
    methods = methods.map { |it| ctx.method(it) }

    while resp = input_queue.dequeue
      output_queue.enqueue methods.inject(resp) { |last, nxt| nxt.call last }
    end

    output_queue.enqueue nil
  end

  def _source(input_queue, output_queue, method, klass, dependencies, extensions)
    ctx = create_context(klass, dependencies, extensions)
    method = ctx.method(method)

    while resp = input_queue.dequeue
      method.call(resp) { |data| output_queue.enqueue(data) }
    end

    output_queue.enqueue nil
  end

end


class PipeDSL
  attr_reader :last_queue
  include Operator

  def self.with(module_ctx, blk, services = [], extensions = {}, config)
    path_builder = QueuePathBuilder.new(config)
    _, input_queue = path_builder.next

    pipe_dsl = new(module_ctx, path_builder, services, extensions, config)
    blk.bind(pipe_dsl).call()

    return input_queue, pipe_dsl.last_queue
  end

  # [deprecated] será implementado na camada superior, em Davinci
  def actor_container(&block)
    input_queue, output_queue = @path_builder.next
    @last_queue = output_queue

    # Create a new PipeDSL instance to execute the block
    inner_dsl = self.class.new(@module, @path_builder, @services, @extensions, @config)

    # Execute the block with the inner_dsl
    block.bind(inner_dsl).call(inner_dsl)

    # Create a Ractor pool and pass the method names and arguments to it
    actor(inner_dsl.method_calls)
  end

  def method_called(method_name, *args)
    @method_calls << { name: method_name, args: args }
  end

  def initialize(ctx, path_builder, services, extensions, config)
    @path_builder = path_builder
    @module = ctx
    @reactor = Async::Task.current
    @config = config
    @method_calls = []

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
    
    # Isso não é performático! mas depois eu altero
    Array(ctx).each do |mdl|
      klass.prepend(mdl)
    end
    @klass = klass
    @ctx = klass.new(@initializers)
  end

  # def sources(method_names)
  #   input_queue, output_queue = @path_builder.next
  #   @last_queue = output_queue
  #   

  #   @reactor.async do
  #     method_names.each do |method_name|
  #       _source(input_queue, output_queue, method_name, @klass, @initializers, @extensions)
  #     end
  #   end
  # end

  def source(method_name)
    method_called(:source, method_name)
    input_queue, output_queue = @path_builder.next
    @last_queue = output_queue

    @reactor.async do
      _source(input_queue, output_queue, method_name, @klass, @initializers, @extensions)

    rescue Async::Stop => error 
      # implement [post_init] here!
      @ctx.post_init() if @ctx.respond_to?("post_init")
    rescue Exception => error
      
    end
  end

  def flow(methods)
    method_called(:flow, methods)
    input_queue, output_queue = @path_builder.next
    @last_queue = output_queue

    @reactor.async do
      super(input_queue, output_queue, methods, @klass, @initializers, @extensions)
    end
  rescue Async::Stop => error 
    # implement [post_init] here!
    @ctx.post_init() if @ctx.respond_to?("post_init")
  end

  def actor(methods)
    method_called(:actor, methods)
    input_queue, output_queue = @path_builder.next
    @last_queue = output_queue
    klass = @klass
    services = Ractor.make_shareable(@services)
    extensions = Ractor.make_shareable(@extensions)
    ractor_count = @config.ractor_count

    ractor_pool = Array.new(ractor_count) do
      Ractor.new(Ractor.make_shareable(methods), klass, services, extensions) do |methods, klass, services, extensions|
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
    rescue Async::Stop => error 
      # implement [post_init] here!
      @ctx.post_init() if @ctx.respond_to?("post_init")
    end

    # Otimizar isso dps
    @reactor.async do
      ractor_index = 0
      while resp = input_queue.dequeue
        ractor_pool[ractor_index].send(resp)
        output_queue.enqueue(ractor_pool[ractor_index].take)
        ractor_index = (ractor_index + 1) % ractor_count
      end

      ractor_pool.each { |ractor| ractor.send(nil) }
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
      puts "POST INITIALIZING!"
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
  def initialize(mdl, drawer:, services:, extensions:, config:)
    

    # podemos definir a ordem no proprio modulo
    if drawer.nil?
      drawer = Array(mdl).first()
    end

    @mdl ||= mdl
    @drawer ||= drawer
    @services ||= services
    @extensions ||= extensions
    @config ||= config
  end
  
  def build_pipeline()
    drawer = @drawer.instance_method 'draw_pipeline'
    return Dsl.with @mdl, drawer, @services, @extensions, @config
  end
end


module Example
  def draw_pipeline()

    source 'load_enterprises'
    source 'load_stablisments'
    source 'load_partners'

    flow ['t1', 't2', 't3']
    actor ['t4', 't5', 't6']
  end
end



module Bpp 

end

if $0 == __FILE__
  # pipe = Pipefy.new(
  #   App,
  #   drawer: Example,
  #   services: [Operator::SPDCommons],
  #   extensions: {
  #     yml: Operator::YAMLLoader.new()
  #   }
  # )
  
  
  pipe = Pipefy.new(
    [App, Bpp],
    drawer: Example,
    services: [Operator::SPDCommons],
    extensions: {
      yml: Operator::YAMLLoader.new()
    },
    config: PipefyConfig.new(ractor_count: 4, queue_size: 50, batch_size: 10)
  )
  
  Async do |it|
  
  
    ctxi, ctxo = pipe.build_pipeline()
    ctxi.enqueue 100
    sleep 1
    puts ctxo.dequeue
    
  
  end
end
