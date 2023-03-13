require 'pry-stack_explorer'

class Darray

    def initialize(inventory, batch)
    end

    def self.init_engine(method, ctx, args, kwargs, fargs, fkwargs)
        engine = self
        @ctx = ctx
        @method = method
        darray = engine.new *args, **kwargs do |batch|
        end

        darray.instance_variable_set "@ctx", ctx
        darray.instance_variable_set "@method", method

        ctx.instance_variable_set("@#{fkwargs.fetch(:gateway_method)}", darray) 
        return darray
    rescue Exception => error
        binding.pry
    end

    def call(data)
        binding.pry
        if !@counter
            @counter = 0
        end
        @counter += 1
        @ctx.send(@method, data)
        
        if @counter > 10 
            return self
        end

        return nil
    end
end

class OnDemmand

    def define_gmethod(gmethod, elastic_object, &blk)
        if !elastic_object.instance_methods.include? gmethod
            binding.pry
            raise Exception, "tem que responder!"
        end


        elastic_object.define_method(:run) do |input|
            self.send(gmethod, input) do |content|
                blk.call content
            end
        end
    end

end

class StreamETL

    def define_gmethod(gmethod, elastic_object, &blk)
        if !elastic_object.instance_methods.include? gmethod
            binding.pry
            raise Exception, "tem que responder!"
        end


        elastic_object.define_method(:run) do |input|
            self.send(gmethod, input) do |content|
                blk.call content
            end
        end
    end

end


class ElasticObject

    # Por hora apenas mockar, preciso descobrir o que vou precisar
    def self.compose(base_klass_or_module, initializers)
        klass = Class.new(ElasticObject)
        if base_klass_or_module.is_a?(Module) && !base_klass_or_module.is_a?(Class)
            klass.include base_klass_or_module
        end
        return klass
    end
end

module Lambda

    class Drawer
        attr_reader :sourcer
        attr_reader :flows
        def initialize()
            @sourcer = nil
            @flows = []
            @report = nil
        end

        def source(gateway_method, klass)
            @sourcer = [gateway_method, klass]
        end
        
        def flow(method, engine, args = [], kwargs = {}, *flow_args, **flow_kwargs)
            @flows << [method, engine, args, kwargs, flow_args, flow_kwargs]
        end
        
        def report(gateway_method)
            @report = gateway_method
        end
    end

    class Worker

        def initialize(job)
            @drawers = []
        end

        # Objeto responsável por fornecer o 'lapies' para escrever o pipeline
        def drawer(elastic_klass = nil)
            @elastic_klass = elastic_klass
            resp = Drawer.new()
            @drawers << [rand(36**20).to_s(36), elastic_klass, resp]
            return resp
        end

      
        # Problema que preciso resolver:
        # [futuro]
        # Um objeto que seja capaz de receber um source, um flows, e outro objetos com sourcers e flows
        # Isso permite com que o source de um objeto na verdade seja o último flow de outro, isso é bem prático
        # Por hora, vamos deixar do jeito simples: retornou nil, é porque ainda não tá pronto para ir pro próximo pipe
        def build_worker()

            @drawers.each do |token, klass_or_module, resp|
                # source: Objeto OnDemmand ou StreamETL
                # flows: objetos que possuem o método call para chamar
                source, flows = resp.sourcer, resp.flows


                # Criando o sourcing
                gmethod, source_klass = resp.sourcer
                elastic_object = klass_or_module.new()
                source_instance = source_klass.new()

                compiled_flows = flows.map do |ctx|
                    binding.pry
                    method, engine_klass, args, kwargs, fargs, fkwargs = ctx
                    if engine_klass.nil?
                        next elastic_object.method(method)
                    end

                    instance_engine = engine_klass.init_engine method, elastic_object, args, kwargs, fargs, fkwargs


                    next instance_engine
                rescue Exception => error

                    binding.pry
                end

                
                # Descobrir como eu posso deixar isso mais eficiente 
                source_instance.define_gmethod(gmethod, klass_or_module) do |initial_val|
                    binding.pry
                    compile_flow_iterator = compiled_flows.each
                    binding.pry
                    transf = compile_flow_iterator.next()
                    resp = transf.call initial_val

                    if resp.nil?
                        break
                    end

                    compiled_flows.inject(initial_val) do |actual, next_flow|
                        binding.pry
                        content = next_flow.call actual
                    end
                end
            end

            return @elastic_klass
        end
    end

    class Job
        def self.init()
            inst = self.new()
            worker = Worker.new inst
            return inst.draw(worker)
        end
    end
end