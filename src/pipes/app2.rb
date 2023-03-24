require './src/envs/actor.rb'

App name: "app2", route: "/ap2" do |it|
    it.env = Env::Default

    it.template [ETL]
    # Serviço para permitir que um determinado arquivo seja visualizado

    get_constants_by_path('./src/services/view.rb') do |file, klass|
        it.use file => klass.new()
    end
    
    
    it.pipeline do 
        src 'extract'
        flw 'transform'
        flw 'load1'
        flw 'load2'
        flw 'load3'
    end

end