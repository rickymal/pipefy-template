require_relative 'yaml_loader.rb'

# A classe service pode receber outros serviços internos, por padrão o objeto ElasticObject recebe os modulos, serviços e extensions
# Os modulos só são passados como parâmetro apenas se o serviço em questão for um modulo (template)
class Elasticsearch < Service
    services yaml: YAMLLoader
    attr_reader :esdev
    attr_reader :esprod

    def on_load(ctx)
        @ctx = ctx
    end

    # Recebe serviços filhos que podem ser carregados
    def initilialize(services, extensions = nil)  
        @esdev = Client::Elasticseach.new services.yaml.get 'esdev'
        @esprod = Client::Elasticseach.new services.yaml.get 'esdev'
    end
end 