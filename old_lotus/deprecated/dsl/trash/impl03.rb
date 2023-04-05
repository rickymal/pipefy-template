require_relative './impl03.2.rb'

module Program


    def t1(data)
        sleep 1
        puts "[t1] somando #{data}"
        return data + 1
    end
    
    def t2(data)
        sleep 1
        puts "[t2] integrando #{data}"
        @hfb << data
        
        return data + 1
    end
    
    def t3(batch)
        sleep 1
        puts "[t3] populando #{batch}"
        return batch.map {|it| it + 10}
    end

    def report()
        {
            nome: "!"
        }
    end
end

# Por hora, pensar apenas no programa
class Pipeline < Lambda::Dashboard

    # Aqui entrada o Lambda
    def build_klass()
        return Class.new().include Program
    end

    def dashboard(drawer)

        
        drawer.pipe :t1
        drawer.pipe :t2, Batch
        drawer.pipe :t3

        # Novo método

        
        # pipeline t1, t2 envia os dados para Batch,
        # Batch os acumula e define quando ocorrerá o próximo despache
        drawer.pipe :t1
        drawer.pipe :t2
        drawer.source Batch 
        
        drawer.pipe :t3
        drawer.pipe :t4
        drawer.source Batch 
        

        drawer.assign()
    end
end


class ETL < Pipeline
    include Program
end

# Apenas para debug inicialmente
etl = ETL.new()
