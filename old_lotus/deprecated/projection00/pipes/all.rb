# Criando um AppContainer:
# Inicializar a aplicação principal
App = Application.new() url: '/app', name: "Dashboard" do |this|
    
    # Carrega o template (módulo) que determina todos os métodos que serão chamados pelo pipeline
    this.template [AppTemplate]
    
    # carrega um arquivo yaml chamado env.yaml e o transforma em hash 
    yaml = YAML.load('./env.yaml')

    load './services/elasticsearch.rb'
    # cria um serviço cujo nome do atributo será 'es', e o valor será o serviço SPD::ElasticService
    this.services es: SPD::ElasticService.new(yaml)
    
    # Carrega extensões
    this.extension []
end

find_ruby_files_by_relative_path('./') do |app|
    App.container name: "example", url: "/example" do |file|
        load "./#{file}"
    end
end

if $0 == __FILE__ 
    # Inicializa a aplicação
    App.new()
end