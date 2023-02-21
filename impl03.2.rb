require 'pry-stack_explorer'
class Darray
end

module OnDemmand
    def gateway()
        return 'run'
    end
end

# Objeto que conterá tudo que é necessário para realizar o desenho
# O 'front-end' do framework Davinci
class Drawer 
    def initialize(dashboard)
        @dash = dashboard
        @SOURCER = Struct.new "Source", :portal, :args, :kwargs
        @FLOW = Struct.new "Flow", :method, :engine, :fargs, :fkwargs, :eargs, :ekwargs
        @seq = Array.new()
    end

    def source(*args, **kwargs)
        @seq << @SOURCER.new(*args, **kwargs)
    end
    
    def flow(*args, **kwargs)
        @seq << @FLOW.new(*args, **kwargs)
    end

    def assign()
        queue = Queue.new @seq
        temp = []
        source = queue.pop()
        @dash.inject_sourcer(source)
        temp << queue.pop()

        while !queue.empty?
            flow = queue.pop()
            
            if flow.engine.nil?
                temp << flow
                next 
            end
            temp << flow
            @dash.assign_dashboard(temp)
            temp.clear()
        end

        if !temp.nil?
            @dash.assign_dashboard temp
        end

    end
end

# Armazenará a fonte, os flows e um ponteiro para o próximo pipesequence
class PipeSequence
    def initialize(drawer_composition)
        @drawer_composition = drawer_composition
    end
end



# Objeto que conterá o molde para a construção do modelo
module Lambda
    class Dashboard
        def initialize()
            @sourcer = nil
            @seq = []
        end

        def inject_sourcer(sourcer)
            @sourcer = sourcer
        end

        def assign_dashboard(drawer_composition)
            binding.pry
            @seq << PipeSequence.new(drawer_composition)
        end

        def initialize()
            @klass_template = Class.new()
            drawer = Drawer.new(self)
            dashboard(drawer)
            binding.pry
            
            return @klass_template
        end
    end
end