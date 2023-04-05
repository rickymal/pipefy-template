
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

if $0 == __FILE__ 
    # Inicializa a aplicação
    App.new()
end