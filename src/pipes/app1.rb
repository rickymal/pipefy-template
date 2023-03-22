require './src/envs/actor.rb'

Davinci.App name: "app", route: "/ap1" do |it|
    it.env = Env::Default

    it.template [ETL]
    # Serviço para permitir que um determinado arquivo seja visualizado

    get_constants_by_path('./src/services/view.rb') do |file, klass|
        it.use file => klass.new()
    end
    
    
    @srcs = Davinci.App name: 'it1' do |it|
        it.pipeline do 
            src 'extract'
        end
    end

    
    @flws = Davinci.App name: 'it2' do |it|
        it.pipeline do 
            flw 'transform'
            flw 'load1'
        end
    end

    @loaders = Davinci.App name: 'it3' do |it|
        it.pipeline do 
            flw 'load2'
            flw 'load3'
        end
    end
end