load "./apps/#{__FILE__}/main.rb"


AsyncQueue = Pipefy::Builder.spawn do |this|

    # Determina de onde os métodos serão puxados para a construção do pipeline
    this.template [App]
    
    find_ruby_files_by_path("./services") do |path|
        find_klass_by_path(path) do |klass|

            # Injeta os serviços para os templates
            this.services(klass)
        end
    end
    
    find_ruby_files_by_path("./services/#{__FILE__}") do |path|
        find_klass_by_path(path) do |klass|

            # Injeta os serviços para os templates
            this.services(klass)
        end
    end
    
    find_ruby_files_by_path("./extensions") do |path|
        find_modules_by_path(path) do |klass|

            # Injeta uma extenção para os templates
            this.extensions(klass)
        end
    end
    
    find_ruby_files_by_path("./extensions/#{__FILE__}") do |path|
        find_modules_by_path(path) do |klass|

            # Injeta uma extenção para os templates
            this.extensions(klass)
        end
    end

    # Método que fará renderizar os dados em uma tela
    view(this, '/app', {request: Request, response: Response})

    # Este método é responsável por cia um children
    p1 = this.tensor
    p2 = this.tensor
    p3 = this.tensor

    sequence(p1, p2, p3)

    # input, output
    io(p1, p3)

    p1.pipeline do |it|
        it.source 'load_enterprises'
        it.source 'load_simple'
        it.source 'load_partners'
        it.source 'load_stablishments'
    end

    p2.pipeline do |it|
        it.flow ['t1','t2','t3']
        it.flow ['t4','t5','t6']
    end

    p3.pipeline do |it|

    end
end

def run(initial_value)
    Async do 
        pipeline = AsyncQueue.new()
        pipeline.send(initial_value)
    end
end