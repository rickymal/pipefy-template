require 'async'
require 'async/container'

class StackExplorer
    def stack(state = {})
      # Execute the block with the current state
      yield(state)
  
      # Remove the inner state changes
      state.each { |key, _value| state.delete(key) }
    end
end



class ContextTreeBuilder
    def initialize()
        @app_stack = []
        @ctx = nil
        @root = nil
    end

    # Não apenas tenho que garantir as extensões e serviços, preciso garantir que os processos filhos também os tenham
    # ContextManager irá cuidar disso


    class ElasticObject
        
        def build_pipeline()
            qi, qo = @pipe.build_pipeline()
        end
        
    end
    
    sleep 1
    
    require './src/core/pipefy.rb'
    class ContextManager
        
        attr_reader :child
        
        def self.create_klass(plug, template, uses, worker, dsl)
            # Criar a classe que contem os serviços que serão utilizados
            # O problema é que quero evitar que o objeto capture o contexto ContextManager, isso irá me prejudicar no uso do Ractor
            # não ligar para isso por hora!
            
            # marshal


            pipelines = Array.new()
            Array(dsl).each do |pipeline|
                if dsl.is_a? Proc 
                    binding.pry
                    modl = Module.new
                    modl.define_method 'draw_pipeline', &dsl
                    pipelines << modl
                end
            end

            pipeline = pipelines.reduce {|pr1, pr2| pr1 >> pr2} 
            klass = Class.new(ElasticObject) { }

            klass.define_method :initialize do |channel|

                # Irá controlar aspectos de execução
                @io = channel self
                
                @pipe = Pipefy.new(
                    template,
                    drawer: dsl,
                    services: uses,
                    extensions: plug,
                    config: PipefyConfig.new(ractor_count: 4, queue_size: 50, batch_size: 10)
                )
            end

            return klass
        end
        
        # Colocar tudo como vetor pois desejo que todos os apps-containers conectados logicamente no mesmo servidor 
        def self.vectorize(context_manager, vect = [], plugs = [], template = [], dsl = [], uses = {}, env = [], route = [])
            
            # applicaation for use
            plugs.push(*context_manager.plugs)
            template.push(*context_manager.templates)
            uses.merge!(context_manager.uses)
            # binding.pry
            env << context_manager.env
            dsl << context_manager.dsl
            route << context_manager.route

            
            if !(dsl.compact.empty? || env.compact.empty?)
                
                vect << [create_klass(plugs.uniq(), template.uniq(), uses, env.compact(), dsl.compact()), context_manager.name, route]
            end

            context_manager.child.each do |child|
                vectorize(child, vect, plugs.dup(), template.dup(), dsl.dup(), uses.dup(), env.dup(), route)
            end
        end
        
        # Por padrão utilizar o próprio contexto para uso
        def pipeline(ctx = self, autorun: false, &blk)
            @ctx = ctx
            @dsl = blk
        end
        
        # Aqui que irei criei todos os pipelines e os executar
        def new()

            ctx = StackExplorer.new()
            flattened_apps = Array.new()
            ContextManager.vectorize self, flattened_apps, ctx

            return flattened_apps
        end


        attr_reader :uses
        attr_reader :plugs
        attr_reader :templates
        attr_reader :route
        attr_reader :name
        attr_reader :templates
        attr_reader :dsl
        attr_writer :env
        attr_accessor :env
        
        def initialize(name = nil, route = nil)
            @uses = {}
            @plugs = [] 
            @child = []
            @templates = []
            @name = name
            @route = route
            @env = nil
            @dsl = nil
            
        end

        def use(**cnt)
            @uses.merge!(cnt)
        end
        
        def plug(*mdl)
            @plugs.push *mdl
        end

        def template(template)
            @templates.push *template
        end

        def insert_children(child)
            @child.push *child
        end
        

    end
    
    def App(name: nil, route: nil, &blk)
        
        ctx = ContextManager.new name, route
        @app_stack.last&.insert_children ctx

        if @app_stack.empty?
            @root = ctx
        end

        @app_stack.push(ctx)
        blk.call(ctx)
        @app_stack.pop()
        
        return ctx
    end
    
    # Onde a magia acontece
    def build(root = @root)
        roots = vectorize_app(root)
    end
    
    def vectorize_app(root)
         
    end
    
    def _get_app_stack()
        @app_stack
    end

    def _set_app_stack(data)
        @app_stack << data
    end
    
    def is_root?(app)
        
        return app == @root
    end

    def sequencialize(*containers)
        src, *flws = containers 
        flws.each do |flw|
            Async do
                while resp = src.take()
                    flw.send resp
                end
            end
            src = flw
        end
    end
    
    def to_h
        instance_variables.each_with_object({}) do |var, hash|
          hash[var.to_s.delete("@")] = instance_variable_get(var)
        end
    end
      
end


Davinci = ContextTreeBuilder.new()
def App(*args, **kwargs, &blk)
    Davinci.App *args, **kwargs, &blk
end
# 
# ctx._get_app_stack
# ctx._set_app_stack 10