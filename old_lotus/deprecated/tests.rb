


app = App name: "Dashboard", route: "/" do |it|
  it.template [AppTemplate]
  it.services es: SPD.new()

  # Processo 1
  Container do  
    App name: "App one", route: "/ap1" do |it|


    end
  end

  # Processo 1
  Container do  
    App name: "App one", route: "/ap1" do |it|


    end
  end


  pipe = it.pipeline attr: etl do |it|
    ir.wait()
    it.src 'source'
    it.flw 'transform'
    it.flw 'load'    
  end

  next pipe
end

app.run()

# Estrutura de dados em árvore
module Tree
    attr_reader :children
    class << self
      attr_accessor :context
    end
  
    def initialize(&blk)
      @children = []
  
      parent = self.class.context
      parent.insert_as_child(self) if parent
  
      self.class.context = self
      instance_eval(&blk) if blk
      self.class.context = parent
    end
  
    def insert_as_child(instance)
      @children << instance
    end
end
  
class App
  include Tree
end

def func &blk
  $pp = App.new do 
    blk.call()
  end
end

app = App.new() do 
    App.new() do 

    end

    App.new() do 

    end

    func do 
        App.new() do 
    
            App.new() do 
    
            end
    
            App.new() do 
    
            end
    
            App.new() do 
    
            end
    
        end
    end
end

# hipergrafo
class Hypergraph
    class << self
      attr_accessor :context
    end
  
    attr_reader :vertices, :hyperedges
  
    def initialize
      @vertices = []
      @hyperedges = []
    end
  
    def add_vertex(vertex)
      @vertices << vertex
    end
  
    def add_hyperedge(*vertices)
      vertices.each { |v| add_vertex(v) unless @vertices.include?(v) }
      @hyperedges << vertices
    end
  
    def self.vertex(vertex, &blk)
      context.add_vertex(vertex)
  
      previous_context = context
      self.context = vertex
      blk.call if blk
      self.context = previous_context
    end
  
    def self.hyperedge(*vertices, &blk)
      context.add_hyperedge(*vertices)
  
      previous_context = context
      vertices.each do |vertex|
        self.context = vertex
        blk.call if blk
      end
      self.context = previous_context
    end
end
  

hypergraph = Hypergraph.new

Hypergraph.context = hypergraph

Hypergraph.vertex :a do
  Hypergraph.vertex :b do
    Hypergraph.hyperedge :c, :d
  end
end
