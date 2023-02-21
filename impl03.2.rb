require 'pry-stack_explorer'
class Darray
end

# Worker
class Tentatives
    attr_accessor :state
    def initialize()
        @counter = 0
    end

    def set_state(state)
        @state = state
    end


    def call(data)
        @counter += 1
        if @counter == 10 
            self.state = :open
            return @counter
        end

        return nil
    end

    def on_change_state(state)
        self.state = :locked
    end

end



# Objeto que conterá tudo que é necessário para realizar o desenho
# O 'front-end' do framework Davinci
class Drawer 
    def initialize(dashboard)
        @dash = dashboard
        @FLOW = Struct.new "Flow", :method, :engine, :fargs, :fkwargs, :eargs, :ekwargs
        @seq = Array.new()
    end

    def flow(*args, **kwargs)
        @seq << @FLOW.new(*args, **kwargs)
    end

    def assign()

        @dash.assign_dashboard @seq
    end
end

# Armazenará a fonte, os flows e um ponteiro para o próximo pipesequence
class PipeSequence
    def initialize()
        @state = :not_builded
        @composition = []
        @virtual_pipeline = []
    end

    def compose(dc)
        @composition << dc
    end

    def build_pipe_flow(klass_ctx, instance_ctx)
        @composition = @composition.flatten().map do |it|
            if it.engine.nil?
                binding.pry
                next instance_ctx.method(it.method())
            end
            worker = it.engine.new()
            worker.set_state :locked
            worker
            next worker
        end 

        @state = :builded

        return self
    end

    def get_pipe_flow()
        pipeflow = [] 
        @composition.each do |it|
            if !it.respond_to?('state')
                pipeflow << it
                next
            end

            if it.respond_to?('state') && it.state != :locked
                pipeflow << it
            end

            if it.respond_to?('state') && it.state == :locked
                pipeflow << it
                break
            end
        end

        return pipeflow
        binding.pry
    end
end

class Ref
end

# Objeto que conterá o molde para a construção do modelo
module Lambda
    class Dashboard

        def initialize()
            @sourcer = nil
            @sequencer = PipeSequence.new()
            @seq = []
            drawer = Drawer.new(self)
            dashboard(drawer)
            binding.pry
            klass_template = build_klass()
            sequence = @sequencer.build_pipe_flow(klass_template, klass_template.new())
            
            sequence.get_pipe_flow()
            binding.pry
            klass_template.define_method :run do |initial_val|
                sequence.get_pipe_flow(self).inject(initial_val) {|it, nxt| nxt.call it }
            end

            klass_template.new.run(10)

            return klass_template
        end


        def assign_dashboard(drawer_composition)
            binding.pry
            @sequencer.compose drawer_composition
        end


    end
end
