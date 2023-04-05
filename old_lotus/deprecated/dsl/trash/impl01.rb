module Program
    def extract()
    end

    def transform()
    end

    def load()
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

class Kod < Lambda::StreamObjectBuilder
        
    def compose()
        return [
            Program, 
            Speedio::Elasticsearch
            Authentication::SPDCommons,
            AutoTest::Obj
        ]
    end

    def report(instance)
        instance.report()
    end

    def create(object, worker)
        instance = object.new()

        pipe = worker.create_pipeline()

        pipe.source(OnDemmandETL, instance.method(:source))
        pipe.source(StreamELT, instance.method(:extract))

        pipe.batch_flow(Darray, 10, 10) 
        pipe.batch_flow(Darray, 10, 10)

        pipe.flow(nil, instance.method(:load))

        return pipe.build_klass()
    end
end


class Job < Lambda::StreamObjectBuilder
    def compose()
        return [
            Program, 
            Speedio::Elasticsearch
            Authentication::SPDCommons,
            AutoTest::Obj
        ]
    end

    def report(instance)
        instance.report()
    end

    def create(object, worker)
        instance = object.new()
        pipe = worker.create_pipeline()

        # Metodo 'source' recebe o nome do método que iniciará o código, um worker, e o método de trabalho (opcional)
        pipe.source :run, OnDemmand, instance.method(:source)
        pipe.flow(nil, instance.method(:transform))

        return pipe.build_klass()
    end
end



job = Job.build()
resp = job.run "Um dadao para ser enviado"

# Como eu vou fazer para criar um método que só exista para o Job?
if resp.is_finished?
    pp 'ok'
end

app = Kod.build()


# Parando para pensar, não faz diferença! Só depende de quando eu vou chamar o método
app.stream_etl.run("Um exemplo de dado que é enviado a vulso")
resp = app.on_demmand_etl.run()

sleep 0.1 while !resp.is_finished?
