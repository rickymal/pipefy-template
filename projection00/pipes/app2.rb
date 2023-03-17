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

if $0 == __FILE__ 
    # Inicializa a aplicação
    App.new()
end