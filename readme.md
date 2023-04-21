
Kamui
# Lotus
**O Projeto está passando por um processo de refatoração. Apaguei tudo e estou reescrevendo**

Lotus é um framework para criar e gerenciar aplicativos assíncronos e pipelines de processamento de dados. Ele permite a criação de aplicativos modulares e extensíveis, com suporte para orquestração, agendamento e integração com serviços externos. Além disso, oferece uma interface no-code, facilitando o desenvolvimento e a integração de aplicações.

## Características

- Criação e gerenciamento de pipelines assíncronos de processamento de dados
- Orquestração de aplicativos em uma estrutura de árvore
- Agendamento de tarefas e processos
- Integração com serviços externos por meio de módulos de serviço
- Interface no-code para desenvolvimento simplificado e visual

## Requisitos
- saber programar


## Instalação

Adicione esta linha ao arquivo Gemfile do seu projeto:
```ruby
gem 'lotus'
```

```bash
bundle install
```

```bash
gem install lotus
```

## Uso
Para começar a usar o Lotus, siga as etapas abaixo:
1. Crie uma instância de Lotus::App e configure-a de acordo com as suas necessidades.
2. Crie um arquivo de configuração (config.yml) para definir os serviços e outras configurações do projeto.
3. Importe e utilize as classes e módulos necessários em seu código Ruby.


## Exemplo de uso
```ruby
require 'lotus'

class HelloWorld
  def call(input)
    puts "Hello, #{input}!"
  end
end

class AddExclamation
  def call(input)
    "#{input}!"
  end
end

# Crie uma instância do Lotus::App
app = Lotus::App.new

# Adicione os componentes ao pipeline
app.pipe(HelloWorld.new)
app.pipe(AddExclamation.new)

# Execute o pipeline
result = app.call('World')

# Imprime "Hello, World!!"
puts result
```

## Desenvolvimento
Após fazer o checkout do repositório, execute bin/setup para instalar as dependências. Em seguida, execute rake spec para executar os testes. Você também pode executar bin/console para iniciar um console interativo para experimentar.

## Contribuição
Pull requests são bem-vindos. Para mudanças importantes, por favor, abra um problema primeiro para discutir o que você gostaria de mudar.

Certifique-se de atualizar os testes conforme apropriado.

## Licença
MIT License