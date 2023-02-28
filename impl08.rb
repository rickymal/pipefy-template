require_relative './impl08.1.rb'

module ETL
    def extract()
        binding.pry
    end
    
    def transform1()
        binding.pry
    end
    
    def transform2()
        binding.pry
    end
    
    def load()
        binding.pry
    end
end

class ETLBatch < Dashboard
    plug [ETL]

    def draw(pipebuilder, elastic_instance_methods = [])
        pipebuilder.yielded 'extract'
        pipebuilder.flow 't1'
        pipebuilder.raw 't2' do |_, _, queue|
            @hfb = Darray.new 10, 10 do |batch|
                queue.enqueue batch 
            end
        end
        pipebuilder.flow 'dispatch'
    end
end


# O método new desenhada o objeto e então com o metodo run, executaremos
Async do |it|
    it.annotate "Applicação principal"
    etl = ETLBatch.new()
    etl.run('mauler')
end