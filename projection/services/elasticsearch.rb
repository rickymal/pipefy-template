require_relative 'yaml_loader.rb'

class YAMLLoader
    def initialize(path)
        @path = path
    end
end

# A classe service pode receber outros serviços internos, por padrão o objeto ElasticObject recebe os modulos, serviços e extensions
# Os modulos só são passados como parâmetro apenas se o serviço em questão for um modulo (template)
# A classe service não existe e seu único propósito é destacar que a classe abaixo é um serviço (apenas!)
class Elasticsearch

    attr_reader :esdev
    attr_reader :esprod

    def on_load(klass)
        klass.attr_accessor __FILE__
        klass.send("#{__FILE__}=", self)
    end

    # Recebe serviços filhos que podem ser carregados
    def initilialize()  
        yaml = YAMLLoader.new('./env.yml')
        @esdev = Client::Elasticseach.new yaml.get 'esdev'
        @esprod = Client::Elasticseach.new yaml.get 'esprod'
    end
end 