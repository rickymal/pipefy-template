class Container
    def initialize()
        @hfb = Array.new()
    end

    def define_queue(queue)
        @queue = queue
    end
end

# Este modulo precise receber o contexto que contenha o @hfb
# opção 1: injeta-lo diretamenta
# opção 2: injeta no ExternalMethod e passar como parâmetro para o modulo 
module InternalMethod
    def extract(data = nil)
        10.times do |y|
            yield y
        end
    end

    def t1(data)
        data + 2
    end

    def t2(data)
        @hfb << data
    end

    def load(batch)
        
    end
end

# Será injetado o 'internal method'
class Lambda
    


# Será injetado em 'self'
module ExternalMethod
    def bound(queue, instance, instance_that_contain_the_method)
        instance.define_queue queue
        @queue = queue
        @instance = instance
        @method = method 
    end
    
    def call(data)
        @method.call data
    end
end

container = Container.new()

container.singleton_class.include ExternalMethod
container.bound(queue, )

Container.include ExternalMethod



module SPD
    module Auth
        module Dataops
            def init(instance)
                YAML.load_attrs './dataops.yaml'
            end
        end
        
        module Atlas
            def init(instance)
            end
        end
    end
end




# DSL assyncronous pipeline Pub sub
# Como criar
# Objeto recebe os modulos descentralizados
# O método internal deve conter seu próprio contexto, assim como o método externo
# Ambos devem pertencem ao mesmo método
EETL = PipeDSL.using do 
    this.methods false
    # normal using first
    it.using Default do 
        it.yielded this.method('extract')
        it.flow this.method('t1')
        it.using Container do
            it.batch this.method('t2')
        end
        it.flow this.method('load')

    end

end


module ETL
    def init(instance)
        @es = YAML.find_config_by_path './config.yaml'
    end

    def find_enterprise(interval)

    end

    def find_stablishments(enterprise)

    end


end

# Contém contexto de execução das ferramentas.
EETL.with [ETL, SPD::Auth::Dataops, SPD::Auth::Atlas]

EETL.new().run(nil)
