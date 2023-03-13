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


class ETLBatch < Lambda::Job
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

        # Recebe um objeto para 'desenhar' o pipeline que será construido
        pipe1 = worker.drawer()
        pipe2 = worker.drawer()

        pipe1.source :extract, OnDemmand
        pipe1.flow [Darray, [10, 10], {}], :t1
        pipe1.flow [Darray, [10, 10], {}], :t2

        pipe2.source :source, StreamETL
        pipe2.flow [Darray, [10, 10], {}], :t1
        pipe2.flow [Darray, [10, 10], {}], :t2

        return worker.build_klass()
    end
end

etl = ETLBatch.init()
etl.extract()
resp = etl.source('One specific data')

pp resp.report()
sleep 0.5 while !resp.is_finished?

class Job < Lambda::Job
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

        # Recebe um objeto para 'desenhar' o pipeline que será construido
        pipe = worker.drawer()
        pipe.source :run, OnDemmand
        pipe.flow [ActorPool, [], {}], :work


        return worker.build_klass()
    end
end


Job.init.run("Test", timeout: 1.hour)