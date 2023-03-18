Davinci.App name: "app", route: "/ap1" do |it|
    
    it.template [ETL]
    # Serviço para permitir que um determinado arquivo seja visualizado

    get_constants_by_path('./src/services/view.rb') do |file, klass|
        binding.pry
        it.use file => klass.new()
    end
    binding.pry

    it.pipeline self do 
        src 'extract'
        flw 'transform'
        act 'load'
    end
end