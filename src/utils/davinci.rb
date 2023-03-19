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

    class Application

        def self.build(context_manager)
            new ContextManager.vectorize(context_manager)
        end

        def initialize(elastic_objects)

        end

        def send()
        end


        def take()
        end 


    end


    class ElasticObject
        def build_pipeline()
            qi, qo = @pipe.build_pipeline()
        end

        def on_receive()
        end
    end

    require './src/core/pipefy.rb'
    class ContextManager
        attr_reader :child

        def self.create_klass(plug, template, uses, worker, dsl)
            # Criar a classe que contem os serviços que serão utilizados
            # O problema é que quero evitar que o objeto capture o contexto ContextManager, isso irá me prejudicar no uso do Ractor
            # não ligar para isso por hora!

            # marshal
            if dsl.is_a? Proc 
                modl = Module.new
                mdl.define_method 'draw_pipeline', &dsl
                dsl = mdl
            end

            klass = Class.new(ElasticObject) { }

            klass.define_method :initialize  do |channel|


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


        end

        # Colocar tudo como vetor pois desejo que todos os apps-containers conectados logicamente no mesmo servidor 
        def self.vectorize(context_manager, vect = [], plugs = [], template = [], dsl = nil, uses = {})
            binding.pry 
            # applicaation for use
            plugs.push(*context_manager.plug)
            template.push(*context_manager.template)
            uses.merge!(context_manager.uses)


            if !(context_manager.dsl.nil? || context_manager.env.nil?)
                vect << create_klass(plugs, template, uses)
            end

            context_manager.child.each do |child|
                vectorize(child, vect, plugs.dup(), template.dup(), uses.dup())
            end
        end

        # Por padrão utilizar o próprio contexto para uso
        def pipeline(ctx = self, autorun: false &blk)
            @ctx = ctx
            @pipeline_drawer = ctx
            @autorun = autorun
        end

        # Aqui que irei criei todos os pipelines e os executar
        def new()
            Application.build self 
        end

        def define_child_app_as(env)
            @env = env
        end

        def initialize(name = nil, route = nil)
            @uses = {}
            @plug = [] 
            @child = []
            @template = []
            @name = name
            @route = route
            @env = nil
            @dsl = nil
            
        end

        def use(**cnt)
            @uses.merge!(cnt)
        end

        def plug(*mdl)
            @plug.push *mdl
        end

        def template(template)
            @template.push *template
        end

        def insert_children(child)
            @child.push *child
        end


    end

    def App(name:, route:, &blk)
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
        binding.pry 
    end

    def _get_app_stack()
        @app_stack
    end

    def _set_app_stack(data)
        @app_stack << data
    end

    def is_root?(app)
        binding.pry
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

# 
# ctx._get_app_stack
# ctx._set_app_stack 10