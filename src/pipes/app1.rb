require './src/envs/actor.rb'

App name: "app", route: "/ap1" do |it|
    it.env = Env::Default

    it.template [ETL]
    # Serviço para permitir que um determinado arquivo seja visualizado

    get_constants_by_path('./src/services/view.rb') do |file, klass|
        it.use file => klass.new()
    end
    
    
    it.pipeline do 
        source 'extract'
        flow ['transform']
        flow ['load1']
        flow ['load2']
        flow ['load3']
    rescue Exception => erro 
        binding.pry
    end

end