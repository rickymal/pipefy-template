require './src/envs/actor.rb'

App name: "app2", route: "/ap2" do |it|
    

    # Permitir com que os apps tenham input e output para serem integrados por fora
    # em um sistema no-coder
    # Esses métodos só irão existir por causa do serviço!
    
    it.env = Env::Default

    it.template [ETL]
    # Serviço para permitir que um determinado arquivo seja visualizado

    get_constants_by_path('./src/services/view.rb') do |file, klass|
        it.use file => klass.new()
    end
    @ap1 = App do |it|

        it.env = Env::Actor

        it.pipeline do 
            source 'extract'
            flow ['transform']
        end
    end
    @ap2 = App do |it|

        it.env = Env::Actor

        it.pipeline do 
            flow ['load1']
            flow ['load2']
            flow ['load3']
        end
    end
    
    # Fazer minha magia mpara que eu consiga conectar esses dois
    it.pipefy(@ap1, @ap2)
    
    # it.pipeline do 
    #     source 'extract'
    #     flow ['transform']
    #     flow ['load1']
    #     flow ['load2']
    #     flow ['load3']
    # end

end