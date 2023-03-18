require 'async'
require 'async/container'

module Davinci
    @app_stack = []
    @ctx = nil

    class BaseContext
    end

    # Não apenas tenho que garantir as extensões e serviços, preciso garantir que os processos filhos também os tenham
    # ContextManager irá cuidar disso
    class ContextManager
        attr_reader :child


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
        @app_stack.push(ctx)
        blk.call(ctx)
        @app_stack.pop()

    end


    def _get_app_stack()
        @app_stack
    end

    module_function :App
    module_function :_get_app_stack
end