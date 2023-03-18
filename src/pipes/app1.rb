Davinci.App name: "app", route: "/ap1" do |it|
    
    it.template [ETL]
    # Serviço para permitir que um determinado arquivo seja visualizado
    get_constants_by_path './services/view.rb' do |path|
        get_constants_by_path(path) do |klass|
            binding.pry
            it.use klass.new()
        end
    end

    it.pipeline do 
        src 'extract'
        flw 'transform'
        act 'load'
    end

end