

# Cria um AppContainer em um processo separado
# this representa o construtor do projeto, ele vai guardar todas as configurações necessárias para iniciar o processo
Pipefy::AppContainer.spawn Async::Container do |this|

    # Carrega o arquivo main que contem o module App que será utilizado no template
    load "./apps/#{__FILE__}/main.rb"

    # Insere os templates (modulos que contem as funções que serão executada)
    this.template [App]
    this.cron "* * * * * * *"

    # Carregar as configurações de ambiente 
    yaml = []
    find_yaml_file_by_path('./') do |yaml|
        yaml << YAML.to_hash(yaml)
    end

    find_yaml_file_by_path("./src/apps/#{__FILE__}/") do |yaml|
        yaml << YAML.to_hash(yaml)
    end

    # Mergeia tudo para mandar para os serviços
    yaml_merged = Hash.new.merge(*yaml)

    # Permite com que a variável 'elastic_size' seja exporta para permitir modificações nela em tempo de execução
    this.allow_changes :elastic_size
    
    find_ruby_files_by_path("./services") do |path|
        find_klass_by_document(path) do |klass|

            # Injeta os serviços para os templates
            this.services(klass.new(yaml_merged))
        end
    end
    
    find_ruby_files_by_path("./services/#{__FILE__}") do |path|
        find_klass_by_document(path) do |klass|

            # Injeta os serviços para os templates
            this.services(klass.new())
        end
    end
    
    find_ruby_files_by_path("./extensions") do |path|
        find_modules_by_path(path) do |mdl|

            # Injeta uma extenção para os templates
            this.extensions(mdl)
        end
    end
    
    find_ruby_files_by_path("./extensions/#{__FILE__}") do |path|
    find_modules_by_path(path) do |mdl|
        
        # Injeta uma extenção para os templates
        this.extensions(mdl)
        end
    end

    # Método que fará renderizar os dados em uma tela
    this.view('/app')


    find_ruby_files_by_path("./extensions") do |path|
        find_modules_by_path(path) do |mdl|

            # Injeta uma extenção para os templates
            this.extensions(mdl)
        end
    end

    this.pipeline do |it|
        it.source 'load_enterprises'
        it.source 'load_simple'
        it.source 'load_stablishment'
        it.source 'load_partners'
        it.flows ['check_destination']
        it.flow ['t1','t2','t3']
    end

    find_ruby_files_by_path("./controller") do |path|
        find_modules_by_path(path) do |klass|

            # Injeta umm controlador para os templates para permitir a integração entre outros template
            this.controller(klass)
        end
    end

end

def run(initial_value)
    Async do |it|
        initial_value.each do |val|
            pipeline = Pipefy::AppContainer.new(name: "update_pt#{val}")
            pipeline.send(val)
        end

        # Como os processos internos utilizarão o async children para rodar, posso rodar isso que vai funcionar
        it.wait()
    end
end