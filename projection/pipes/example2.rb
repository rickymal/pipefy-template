load "./apps/#{__FILE__}/main.rb"

# Cria um AppContainer
Pipefy::AppContainer.spawn do |this|

    # Insere os templates (modulos que contem as funções que serão executada)
    this.template [App]
    
    find_ruby_files_by_path("./services") do |path|
        find_klass_by_document(path) do |klass|

            # Injeta os serviços para os templates
            this.services(klass)
        end
    end
    
    find_ruby_files_by_path("./services/#{__FILE__}") do |path|
        find_klass_by_document(path) do |klass|

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
    view(this, '/app')

    # Este método é responsável por cia um children
    p1 = this.tensor using: Default
    p2 = this.tensor using: Actor
    p3 = this.tensor using: Container 

    # Declarando aqui que os app-containers estão conectados.
    sequence(p1, p2, p3)

    # input, output
    io(p1, p3)

    p1.pipeline do |it|
        it.source 'load_enterprises'
        it.source 'load_simple'
        it.source 'load_stablishment'
        it.source 'load_partners'
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
        pipeline = Pipefy::AppContainer.new()
        pipeline.send(initial_value)
    end
end