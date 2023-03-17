Davinci::App name: "app", route: "/ap1" do |it|

    it.template [ETL]
    # Serviço para permitir que um determinado arquivo seja visualizado
    get_constants_by_path './services/view.rb' do |klass|
        it.use klass.new()
    end

    it.pipeline do 
        src 'extract'
        flw 'transform'
        act 'load'
    end

end