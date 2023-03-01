require_relative './impl08.1.rb'

module ETL
    def extract()
        10.times do |yld|
            yield yld
        end
    end
    
    def t1(data)
        binding.pry
        return data * 2
    end
    
    def t2(data)
        binding.pry
    end
    
    def load(data)
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
        pipebuilder.flow 'load'
    end
end


# O método new desenhada o objeto e então com o metodo run, executaremos
Async do |it|
    it.annotate "Applicação principal"
    etl = ETLBatch.new()
    etl.run('mauler')
end