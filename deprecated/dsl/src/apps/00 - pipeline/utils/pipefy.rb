require_relative 'pipe_dsl.rb'

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
        return PipeDSL.with @mdl, drawer, @services, @extensions
    end
end