require 'pry-stack_explorer'
class Darray
end


class NewBatch
    def initializer(klass_template, instance_template, sym_method)

    end

    def set_state(state)
        @state = state
    end

    # Como permitir com que o Batch controle e defina o ambiente de execução?
    def dispatch_data(data)

    end
end

# Worker
class Batch
    attr_accessor :state
    def initialize(klass_ctx, instance_ctx, sym_method)
        @klass_ctx = klass_ctx
        @instance_ctx = instance_ctx
        @sym_method = sym_method
        @counter = 0

        @instance_ctx
        @instance_ctx.instance_variable_set "@hfb", []

    end

    def set_state(state)
        @state = state
    end


    def call(data)
        mth = @instance_ctx.method(@sym_method)
        mth.call data

        
        @counter += 1
        if @counter == 10 
            @counter = 0
            self.state = :open
            hfb = @instance_ctx.instance_variable_get "@hfb"
            @instance_ctx.instance_variable_set "@hfb", []
            return hfb
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

    def pipe(*args, **kwargs)
        @seq << @FLOW.new(*args, **kwargs)
    end

    def assign()
        queue = Queue.new @seq
        package = []
        while !queue.empty?
            content = queue.pop()
            
            package << content

            if !content.engine.nil?
                @dash.assign_dashboard package
                package = Array.new()
            end
        end

        @dash.assign_dashboard package if !package.empty?

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

        



        flows = @composition.map do |it|
            it.map do |it|
                if it.engine.nil?
                    next instance_ctx.method(it.method())
                end
                worker = it.engine.new(klass_ctx, instance_ctx, it.method())
                worker.set_state :locked
                next worker
            end
        end 
        
        @state = :builded

        @virtual_pipeline = flows

        @virtual_pipeline << [nil]

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
        
    end

    def inject(initial_val, &blk)
        @virtual_pipeline.inject(initial_val) do |init, seq|
            if seq.nil?
                return
            end

            resp = blk.call init, seq
            begin
                if seq.last.respond_to?('state') && seq.last.state == :locked
                    break
                end
            rescue => exception
            #    binding.pry 
            end
            $flagoso = true

            next resp
        end

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
            
            klass_template = build_klass()
            instance_template = klass_template.new()
            sequence = @sequencer.build_pipe_flow(klass_template, instance_template)
            
            
            klass_template.define_method :run do |initial_val|

                # Isolar os pipe sequence em fatias maiores que podem estar em ambientes diferentes
                sequence.inject(initial_val) do |it, nxt|
                    if nxt == [nil] || it.nil?
                        return
                    end

                    # Concatena pipe_sequence que estão no mesmo ambiente
                    rp = nxt.inject(it) {|it, nxt| nxt.call it } rescue binding.pry
                    # binding.pry if $flagoso

                    next rp
                end
            end

            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)
            instance_template.run(10)

            return instance_template
        end


        def assign_dashboard(drawer_composition)
            
            @sequencer.compose drawer_composition
        end


    end
end
