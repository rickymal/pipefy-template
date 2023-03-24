require 'async'
require 'async/container'



class ContextTreeBuilder
    def initialize()
        @app_stack = []
        @ctx = nil
        @root = nil
    end

    # Não apenas tenho que garantir as extensões e serviços, preciso garantir que os processos filhos também os tenham
    # ContextManager irá cuidar disso


    class Activity
        
        def build_pipeline()
            qi, qo = @pipe.build_pipeline()
        end
        
    end
    
    sleep 1
    
    require './src/core/pipefy.rb'
    class ContextManager
        attr_reader :uses
        attr_reader :plugs
        attr_reader :templates
        attr_reader :route
        attr_reader :name
        attr_reader :dsl
        attr_accessor :env
        attr_reader :child
        
        def self.create_klass(dependencies)
            # Criar a classe que contem os serviços que serão utilizados
            # O problema é que quero evitar que o objeto capture o contexto ContextManager, isso irá me prejudicar no uso do Ractor
            # não ligar para isso por hora!

            pipelines = Array.new()
            dsl = dependencies[:dsl].compact()
            Array(dsl).each do |pipeline|
                if dsl.is_a? Proc 
                    modl = Module.new
                    modl.define_method 'draw_pipeline', &dsl
                    pipelines << modl
                end
            end

            pipeline = pipelines.reduce(lambda {}) {|pr1, pr2| pr1 >> pr2} 
            klass = Class.new(Activity) { }

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

        def self.has_dsl(dep)
            return !dep[:dsl].compact().empty?
        end

        def self.has_env(dep)
            return !dep[:env].compact().empty?
        end
        
        $global = []
        $global2 = []
        $cnt = 0
        # Colocar tudo como vetor pois desejo que todos os apps-containers conectados logicamente no mesmo servidor 
        def self.vectorize(context_manager, vect = [], dependencies = {})
        # def self.vectorize(context_manager, vect = [], stack = nil)
            dependencies[:plugs] << context_manager.plugs.dup()
            dependencies[:templates] << context_manager.templates.dup()
            dependencies[:uses] << context_manager.uses.dup()
            dependencies[:env] << context_manager.env.dup()
            dependencies[:dsl] << context_manager.dsl.dup()
            dependencies[:route] << context_manager.route.dup()
            dependencies[:name] << context_manager.name.dup()
            $global << dependencies
            
            
            if has_dsl(dependencies) && has_env(dependencies) 
                
                vect << {
                    klass: create_klass(dependencies),
                    name: dependencies[:name].last(),
                    route: dependencies[:route].last.nil? ? nil : dependencies[:route].join()
                }
            end

            context_manager.child.each do |child|
                vectorize(child, vect, dependencies)
            end
            dependencies[:route].pop()
        end
        
        # Por padrão utilizar o próprio contexto para uso
        def pipeline(ctx = self, autorun: false, &blk)
            @ctx = ctx
            @dsl = blk
        end
        
        # Aqui que irei criei todos os pipelines e os executar
        def new()

            dependencies = {
                uses: [],
                plugs: [],
                templates: [],
                route: [],
                name: [],
                dsl: [],
                env: [],
                uses: [],
            }
            activities = Array.new()
            ContextManager.vectorize self, activities, dependencies

            return activities
        end


        


        
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
        $global2 << {
            name:, route:
        }
        $cnt += 1
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