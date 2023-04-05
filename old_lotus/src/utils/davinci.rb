require 'async'
require 'async/container'


# Para testes apenas
module Template
    def extract(data)
        puts "usando #{data} faça:".center 80, '-'
        # data["query1"].to_i
        10.times do |ctx|
            puts "sourcerizando valor #{ctx}"
            yield ctx
        end
    end

    def transform(data)
        puts "transformando em transform #{data}"
        data + 1
    end
    
    def load1(data)
        puts "transformando em #{__method__} #{data}"
        data + 1
    end
    
    def load2(data)
        puts "transformando em load2 #{data}"
        data + 1
    end

    def load3(data)
        puts "transformando em load3 #{data}"
        data + 1
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


    class Activity
        attr_accessor :pipe
        attr_accessor :qi
        attr_accessor :qo
        
        def build_pipeline()
            # binding.pry
            @_env = @env.new(@pipes)
            # binding.pry
            # if @pipes.size() > 1 || true

            #     # Preciso fazer com que essa comunicação ocorra caramba
                
            #     pipelines = @pipes.map {|it| it.build_pipeline()}
            #     @qi = pipelines[0][0]
            #     @qo = pipelines[-1][-1]
            #     pipelines.each_cons(2) do |p1, p2|
            #         Async do 
            #             while resp = p1[1].dequeue
            #                 p2[0].enqueue resp
            #             end
            #         end
            #     end
            # else
            #     @qi, @qo = @pipe.build_pipeline()
            # end
            return self
        end


        def send(data)
            @_env.send(data)
        end

        def size()
            @_env.size()
        end

        def take()
            @_env.take()
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
            dsl = dependencies[:dsl].compact().last()
            
            mdls = []
            Array(dsl).each do |dsl|
                modl = Module.new
                modl.define_method 'draw_pipeline', &dsl 
                mdls << Ractor.make_shareable(modl)
            end


            # Array(dsl).each do |pipeline|
            # end
            

            # pipeline = pipelines.reduce(lambda {}) {|pr1, pr2| pr1 >> pr2} 

            
            klass = Class.new(Activity) { }

            # Seria interessant se isso pudesse ser feito, e a classe pudesse ser unica ou do tipo
            # singleton compartilhável por meio de um ractor (classe remota)
            # pensar nessa implementação
            # klass.include_klass Activity
            
            klass.define_method :initialize do |env|

                @env = env

                # # Irá controlar aspectos de execução
                # @io = channel self
                @pipes = Array(mdls).map do |modl|
                    @pipe = Pipefy.new(
                        [Template],
                        drawer: modl,
                        services: dependencies[:plugs].flatten().uniq(),
                        extensions: Hash.new.merge(*dependencies[:uses]),
                        config: PipefyConfig.new(ractor_count: 4, queue_size: 50, batch_size: 10)
                    )
                end
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
                    route: dependencies[:route].last.nil? ? nil : dependencies[:route].join(),
                    env: dependencies[:env].compact().last()
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

        def pipefy(*pipelines)
            dsls = pipelines.map {|it| it.dsl}
            @dsl = dsls
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