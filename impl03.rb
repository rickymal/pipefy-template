module Program
    def extract()
    end

    def transform()
    end

    def load()
    end

    def job()
    end

    def report()
        {
            report: "Isso é um exemplo de um relatório"
        }
    end
end

module Speedio
    module Elasticsearch
    end
end

module Authentication
    module SPDCommons
    end
end

class Darray
    def initialize(inventory, batch)
    end

    def check_dispatching()
    end
end

module Obj 
    class AutoTest
    
        def pre_init(klass)
        end
    
        def init()
        end
    
        def post_init(instance)
        end

    end
end

module SPDCommons
    def compose()
        [
            Speedio::Elasticsearch
            Authentication::SPDCommons,
            AutoTest::Obj
        ]
    end
end

class ETLBatch < Lambda::Job
    include SPDCommons 

    def draw(worker)
        # Recebe um objeto para 'desenhar' o pipeline que será construido
        pipe1 = worker.drawer(Program)
        pipe2 = worker.drawer(Program)
    
        pipe1.source :extract, OnDemmand # Criará o método 'run'
        pipe1.flow [Darray, [10, 10], {}], :t1
        pipe1.flow [Darray, [10, 10], {}], :t2
        pipe1.report :report
        
        pipe2.source :source, StreamETL # Criará o método 'send'
        pipe2.flow [Darray, [10, 10], {}], :t1
        pipe2.flow [Darray, [10, 10], {}], :t2
        pipe2.report :report

        return worker.build_worker()
    end

end

etl = ETLBatch.init()

Async { etl.run() }

10.times do
    resp = etl.send 'dynamic content'
end


# === Criando os recursos para o job

module Lambda

    class Drawer
        def initialize(klass_or_module, ctx, token)
            @sentence = []
            @ctx = ctx
            @token = token
        end

        def source(gateway_method, klass)
            @ctx.set_sourcing(gateway_method, klass, @token)
        end
        
        def flow(composition, token)
            @ctx.set_flow(composition, @token)
        end
        
        def report()
            @ctx.set_report(gateway_method, klass, @token)
        end
    end

    class Worker
        def initialize()
            @token = Hash.new() do |k,v|
                k[v] = {
                    'source' => [],
                    'flow' => []
                }
            end
            @reportes = Array.new()

            DecoratorDelegate.new {self => :source}, Drawer
            DecoratorDelegate.new {self => :flow}, Drawer
            DecoratorDelegate.new {self => :report}, Drawer
        end

        def drawer(klass_or_module)
            

            id_token = (0...20).map { (65 + rand(26)).chr }.join
            return @obj_delegate.delegate(self, id_token)
        end

        def build_worker()

        end

    end

    class Job
        def self.init()
            worker = Worker.new()
            draw(worker)
        end
    end
end

pp resp.report()
sleep 0.5 while !resp.is_finished?

class Job < Lambda::Job
    include SPDCommons 

    def draw(worker)
        # Recebe um objeto para 'desenhar' o pipeline que será construido
        pipe1 = worker.drawer(Program)
        pipe1.source :extract, OnDemmand # Criará o método 'run'
        pipe1.flow ActorPool, :t1
    end

end

job = Job.init()

job.run "Send content"