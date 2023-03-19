require './src/envs/actor.rb'

Davinci.App name: "app", route: "/ap1" do |it|
    attr_reader :srcs
    attr_reader :flws
    attr_reader :loaders

    it.set_default_enviroment Env::Actor


    it.template [ETL]
    # Serviço para permitir que um determinado arquivo seja visualizado

    get_constants_by_path('./src/services/view.rb') do |file, klass|
        it.use file => klass.new()
    end
    
    @srcs = Davinci.App do |it|
        it.pipeline do 
            src 'extract'
        end
    end

    @flws = Davinci.App do |it|
        it.pipeline do 
            flw 'transform'
            flw 'load1'
        end
    end

    @loaders = Davinci.App do |it|
        it.pipeline do 
            flw 'load2'
            flw 'load3'
        end
    end

end