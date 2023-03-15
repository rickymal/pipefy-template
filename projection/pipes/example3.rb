# Criando um AppContainer:
# Contem um conjunto de códigos para trabalho
app = Davinci::Container.new url: '/app', name: "Applicação principal" do |this|
    
    # Carrega o template que dita como esse determinado dado irá trabalhar
    app.template [App]
    
    # Carrega um serviço qualquer que será armazenado no template
    yaml = YAML.load('./env.yaml')
    app.services es: SPD::ElasticService.new(yaml)
    
    app.extension []
end

# Cria um children para observamos o comportamento, e responsável por carregar os dados
app.child Davinci::Container.new(app: 'extract', using: ) do |this|

    app.pipeline do |it|
        it.source 'load1'
        it.source 'load2'
        it.source 'load3'
    end
end

# Cria um children para observamos o comportamento, e responsável por transformar os dados
app.child Davinci::Container.new(app: 'transform') do |this|
    app.pipeline do |it|
        it.flow ['t1','t2','t3']
    end
end


# Inicia a applicação
qi, qo = app.init(url: '/app')

qo.enqueue 100