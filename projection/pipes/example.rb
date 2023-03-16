# Criando um AppContainer:
# Inicializar a aplicação principal
App = Davinci::Application.new() url: '/app', name: "Dashboard" do |this|
    
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

# Criar uma aplicação menor utilizando em um processo separado (container por causa da gem async-container, pois usará o Async::Container)
# o parametro :name determina o nome da aplicação
# o parametro :url me dirá o endpoint onde poderei obter informações sobre a aplicação. Perceba que ele é um 'children' de App, o que significa que para acessa-lo usaremos o ednpoint /app/p1
App.container name: 'aplicação 1', url: '/p1' do |this|

    # Considerando que este container é um 'children' do App, ele conterá todos os templates que existem no App (AppTemplate) mais os inseridos aqui
    # A lógica de repete para a inserção de serviços também.
    this.template [BppTemplate]

    this.pipeline do |it|

        # O método 'src' pegará o método 'load1' presente em algum template e o executará, porém o 'src' indica que o método retornará os dados utilizando o 'yield'
        it.src 'load1'
        it.src 'load2'
        it.src 'load3'

        # O método 'flw' pegará o método 't1', 't2' e 't3' presente em algum template e o executará, em sequencia, porém o 'flw' indica que o método retornará os dados utilizando o 'return'
        it.flw ['t1','t2','t3']
    end
end

# Criar uma aplicação menor utilizando em um processo separado
pipe = App.container name: 'aplicação 2', url: '/p2' do |this|
    this.pipeline do |it|
        # O método 'app' chamará os processos criados pela variávels 'pipe' cujo parametro :name for igual
        it.app 'source'
        it.app 'transform1'
        it.app 'transform2'
    end
end

# Redistruir a aplicação em partes menores
# A aplicação agora é composta por uma thread separada, o método 'async' utiliza a gem 'async' para criar este processo
pipe.async name: 'source' do |this|
    this.pipeline do |it|
        it.src 'sr1'
        it.src 'sr2'
        it.src 'sr3'
    end
end
# A aplicação agora é composta por uma thread rodando dentro de um ractor
pipe.actor name: 'transform1' do |this|
    this.pipeline do |it|
        it.flw 't1'
        it.flw 't2'
        it.flw 't3'
    end
end

pipe.async app: 'transform2' do |this|
    this.pipeline do |it|
        it.flw 't4'
        it.flw 't5'
        it.flw 't6'
    end
end

# Inicializa a aplicação
App.new()