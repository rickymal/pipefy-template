class Dashboard
    def initialize(programs)
      @programs = programs
    end
  
    def draw(&block)
      drawer = Drawer.new
  
      @programs.each do |program|
        drawer.instance_eval(&program)
      end
  
      drawer.instance_eval(&block)
  
      drawer
    end
  end
  
  class Drawer
    def src(method_name)
      @source = method_name
    end
  
    def flow(method_name, with: {})
      transformer = Transformer.new(method_name)
      transformer.modifier = with[:pre_load] if with[:pre_load]
  
      @transformers ||= []
      @transformers << transformer
    end
  
    def run
      data = []
      send(@source) do |datum|
        data << datum
      end
  
      @transformers.each do |transformer|
        data = transformer.call(data)
      end
  
      data.each do |datum|
        load(datum)
      end
    end
  end
  
  class Transformer
    attr_accessor :modifier
  
    def initialize(method_name)
      @method_name = method_name
    end
  
    def call(data)
      output = []
      buffer = Darray.new(@method_name)
      data.each do |datum|
        buffer << datum
        if buffer.size == @modifier
          output << buffer.process
          buffer.clear
        end
      end
      output
    end
  end
  
  class Darray
    def initialize(method_name)
      @method_name = method_name
      @data = []
    end
  
    def <<(datum)
      @data << datum
    end
  
    def size
      @data.size
    end
  
    def clear
      @data.clear
    end
  
    def process
      Program.new.send(@method_name, @data)
    end
  end
  
  class Program
    def extract()
      10.times do |ctx|
        yield ctx
      end
    end
  
    def transform(data)
      @hfb ||= Darray.new(__method__)
      @hfb << data
    end
  
    def load(data)
      puts data.map { |datum| datum + 1 }.inspect
    end
  end
  
  # Implementação
  ETLBatch = Dashboard.new([Program]).draw do 
    src :extract
    flow :transform, with: {pre_load: 10}
    flow :load
  
    run
  end
  