require_relative './impl08.1.rb'

module ETL
    def extract(optional_data = nil)
        10.times do |yld|
            yield yld
        end
    end
    
    def t1(data)
        return data * 2
    end
    
    def t2(data)
        yield data
    end
    
    def load(data)
        binding.pry
    end
end

class ETLBatch < Dashboard
    plug [ETL]

    def draw(pipebuilder, elastic_klass = [])

        pipebuilder.yielded 'extract'
        pipebuilder.flow 't1'
        pipebuilder.batch 't2' 
        pipebuilder.flow 'load'
    end
end


# O método new desenhada o objeto e então com o metodo run, executaremos
Async do |it|
    it.annotate "Applicação principal"
    etl = ETLBatch.new()
    etl.run('mauler')
end