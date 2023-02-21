require_relative './impl03.2.rb'

module Program

    def t1 data
        @hfb1 << 10
    end

    def t2 
        @hfb2
    end

    def t3 multi

    end

    def report()
        {
            nome: "!"
        }
    end
end

# Por hora, pensar apenas no programa
class AbstractETL < Lambda::Dashboard

    def dashboard(drawer)

        drawer.source OnDemmand # Criará o método 'run'
        drawer.flow :t1, nil
        drawer.flow :t2, Darray, [10, 10], {}, gateway_method: :hfb
        drawer.flow :t3, nil

        drawer.assign()
    end
end


class ETL < AbstractETL
    include Program
end

# Apenas para debug inicialmente
etl = ETL.new()

etl.run()