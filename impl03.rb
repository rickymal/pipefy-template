require_relative './impl03.2.rb'

module Program

    def state()
        return :open
    end

    def t1(data)
        data + 1
    end

    def t2 
        @hfb << 10
    end

    def t3(batch)
        batch.map {|it| it + 10}
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

        drawer.flow :t1
        drawer.flow :t2, Tentatives
        drawer.flow :t3

        drawer.assign()
    end
end


class ETL < Pipeline
    include Program
end

# Apenas para debug inicialmente
etl = ETL.new()

etl.run()