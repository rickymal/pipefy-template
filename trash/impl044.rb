require_relative './impl04.1.rb'

module Program



    def t1(data)
        sleep 1
        puts "[t1] somando #{data}"
        return data + 1
    end
    
    def t2(data)
        sleep 1
        puts "[t2] integrando #{data}"
        return data + 1
    end

    def set_t3(hfb)
        @hfb1 = hfb
    end
    
    def t3(data)
        @hfb1 << data 
        return nil
    end

    def t4(data)
        sleep 1
        puts "[t1] somando #{data}"
        return data + 1
    end
    
    def t5(data)
        sleep 1
        puts "[t2] integrando #{data}"
        @hfb << data
        
    end

    def set_t6(hfb)
        @hfb2 = hfb
    end
    
    def t6(batch)
        sleep 1
        puts "[t3] populando #{batch}"
        return batch.map {|it| it + 10}
    end

end


# Objeto responsável por realizar um desenho usando o modulo Program como template
Pipeline = CoreDrawer.draw [Program] do |drawer|

    drawer.flow :t1 
    drawer.flow :t2 
    drawer.to Batch, :t3

    drawer.flow :t4
    drawer.flow :t5 
    drawer.to Batch, :t6

    # drawer.flow :t4
    # drawer.flow :t5
    # drawer.to Batch, :t6
    
    # # Versão futura! Cada pipe pode ter seu próprio template e receber seu ambiente de execução, como uma task por ex

    # Receber o modulo async, puxa a task async e a utiliza!
    # Fazer com que a sequencia não crie uma dependencia entre os ambientes:
        # um batch cria uma thread que faz com que os outros flows rodem em uma outra, e o batch interno criara
        # outra thread, uma será thread filha da outra.
        # eu quero que tudo seja gerenciado por um único thread manager
    # drawer.enviroment Async
    # drawer.with Program
    # drawer.pipe :t1 
    # drawer.pipe :t2 
    # drawer.finally Batch

    # drawer.with Program
    # drawer.pipe :t3
    # drawer.pipe :t4
    # drawer.finally Batch
    
end
