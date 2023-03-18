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
    class ContextManager
        attr_reader :child


        # Por padrão utilizar o próprio contexto para uso
        def pipeline(ctx = self, &blk)
            @ctx = ctx
            @pipeline_drawer = ctx
        end


        def define_child_app_as(env)
            @env = env
        end

        def initialize(name, route)
            @uses = {}
            @plug = [] 
            @name = name
            @route = route
            @child = []
            @template = []
            @env = nil
            @dsl = nil
        end

        def use(**cnt)
            @uses.merge!(cnt)
        end

        def plug(mdl)
            @plug << mdl
        end

        def template(template)
            @template << template
        end

        def insert_children(child)
            @child << child
        end
    end

    def App(name:, route:, &blk)
        
        ctx = ContextManager.new name, route
        @app_stack.last&.insert_children ctx

        if @app_stack.empty?
            @root = ctx
        else
            binding.pry
        end

        @app_stack.push(ctx)
        blk.call(ctx)
        @app_stack.pop()

        if @app_stack.empty?
            build()
        end

    end

    # Onde a magia acontece
    def build()
        binding.pry
    end

    def _get_app_stack()
        @app_stack
    end

    def _set_app_stack(data)
        @app_stack << data
    end

    # module_function :App
    # module_function :_get_app_stack
    # module_function :_set_app_stack
end


Davinci = ContextTreeBuilder.new()

# binding.pry
# ctx._get_app_stack
# ctx._set_app_stack 10