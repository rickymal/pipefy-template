# Lotus


Lotus é um framework para criar e gerenciar aplicativos assíncronos e pipelines de processamento de dados. Ele permite a criação de aplicativos modulares e extensíveis, com suporte para orquestração, agendamento e integração com serviços externos.



## Características

- Criação e gerenciamento de pipelines assíncronos de processamento de dados
- Orquestração de aplicativos em uma estrutura de árvore
- Agendamento de tarefas e processos
- Integração com serviços externos por meio de módulos de serviço

## Motivação
- Em um mundo em constante evolução, o campo da programação também está mudando. Acreditamos que, no futuro, existirão dois tipos de programadores: os que criam ferramentas e os que as utilizam. Para desenvolver ferramentas poderosas como o React ou o Apache Airflow, é exigido um nível de conhecimento que normalmente não é requisitado quando simplesmente usamos essas ferramentas. Este fato cria um equilíbrio delicado entre flexibilidade e capacidade. 

- Ferramentas e frameworks de alto nível tendem a ser menos flexíveis, enquanto aqueles de baixo nível fornecem maior flexibilidade. No entanto, a metaprogramação surge como uma solução para essa dicotomia, permitindo a criação de ferramentas que são simultaneamente simples e flexíveis. É nessa interseção que vemos o verdadeiro potencial do Ruby.

- Python tem sido a linguagem de escolha quando se trata de Big Data. No entanto, quando se trata especificamente de engenharia de dados, acreditamos que outras linguagens podem ter uma performance superior. Ruby, com sua metaprogramação poderosa e flexibilidade inerente, é uma dessas linguagens.

- Lotus nasce como um framework para alavancar o poder do Ruby na engenharia de dados. Nosso objetivo é fornecer uma ferramenta que torna a criação e gerenciamento de aplicativos assíncronos e pipelines de processamento de dados uma tarefa simples e intuitiva. Desejamos proporcionar a todos a possibilidade de criar, gerenciar e estender seus próprios aplicativos, não importa quão complexos eles possam se tornar.

- Ao lidar com a construção de pipelines para big data, um alto grau de concorrência é necessário, geralmente gerenciado por meio da criação de workers. Existem bibliotecas, como a Concurrent::Async, que lidam muito bem com esse aspecto. No entanto, a criação e destruição de threads em scripts podem não maximizar o desempenho do sistema, nem tirar proveito completo da flexibilidade oferecida pelo GIL (Global Interpreter Lock). Muitas vezes, criamos threads em trechos específicos de código para garantir agilidade, porém muitas dessas operações continuam sendo CPU-bound na thread. No entanto, quando falamos sobre engenharia de dados e a construção de pipelines, podemos atribuir cada pipe a uma funcionalidade específica, assegurando que as operações CPU-bound e IO-bound sejam processadas em seus respectivos pipes. Isso nos permite, por meio de fibras, threads ou até atores (todos esses são utilizados), alcançar uma maior eficiência no código. Cada pipe terá sua própria fibra, thread ou ator, o que é excelente, pois cada pipe é independente. Esta independência garante uma otimização do processamento, tirando proveito máximo do sistema e proporcionando uma melhor performance ao pipeline. Em outras palavras: cada pipe teu sem próprio worker!

-  Ruby tem uma sintaxe limpa e fácil de entender que permite aos programadores se concentrarem mais na lógica do negócio do que em detalhes da linguagem de programação. Essa simplicidade é essencial ao lidar com aplicações assíncronas e pipelines de processamento de dados, que podem se tornar complexos muito rapidamente. Com Ruby, o código se torna mais legível e, portanto, mais fácil de gerenciar e manter.

- a metaprogramação é um aspecto poderoso do Ruby. Ela permite aos desenvolvedores escrever programas que geram ou modificam outros programas (ou a si mesmos) durante a execução. Isso pode levar a um código mais enxuto e eficiente, o que é essencial ao lidar com grandes volumes de dados e operações complexas.

- Ruby é uma linguagem madura com uma grande comunidade de desenvolvedores. Isso significa que há uma abundância de bibliotecas, tutoriais, fóruns de discussão e outros recursos disponíveis. A solidez de Ruby garante que o Lotus estará construído sobre uma base estável e robusta.

- Ruby tem várias abstrações integradas para lidar com a concorrência e o paralelismo, o que é uma vantagem importante para a programação assíncrona e o processamento de dados. Essas abstrações podem facilitar a criação e gerenciamento de tarefas simultâneas, melhorando o desempenho geral das aplicações.

- Ruby tem um ecossistema rico de bibliotecas, chamadas de gems, e uma ferramenta robusta de gerenciamento de dependências, chamada Bundler. Isso facilita a extensibilidade do Lotus, pois os desenvolvedores podem facilmente incorporar novas funcionalidades ao seus projetos por meio de gems e gerenciar suas dependências com o Bundler.

- Ruby tem um recurso único e poderoso chamado blocos, que são essencialmente trechos de código que podem ser passados como parâmetros para métodos. Juntamente com Procs e lambdas, eles oferecem uma maneira elegante de lidar com callbacks e rotinas assíncronas, o que é particularmente útil em pipelines de processamento de dados. 

- Ruby é uma linguagem muito flexível, que permite aos programadores a liberdade de desenhar suas soluções de forma que melhor atenda suas necessidades específicas. Essa flexibilidade é especialmente útil na engenharia de dados, onde cada problema pode exigir uma solução única.

- Ruby, juntamente com seu ecossistema de ferramentas de teste, facilita a criação de testes abrangentes para o código. Isto é crucial para garantir a robustez e confiabilidade dos pipelines de processamento de dados criados com Lotus.
  
Em resumo, acreditamos que Ruby, com suas características únicas, oferece uma base sólida para o desenvolvimento de aplicativos assíncronos e pipelines de processamento de dados com o Lotus.

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


lotus = Lotus::Container.new()
lotus.name = 'Simples ETL'
lotus.pipefy(HelloWorld, Lotus::Method::Flow)
lotus.pipefy(AddExclamation, Lotus::Method::Flow)

Async { lotus.new.call([]) }.wait()
```

- O projeto não está completo, porém abri mão de simplicidade para garantir a funcionalidade. Porém já é funcional.

## Desenvolvimento
Após fazer o checkout do repositório, execute bin/setup para instalar as dependências. Em seguida, execute rake spec para executar os testes. Você também pode executar bin/console para iniciar um console interativo para experimentar.

## Contribuição
Pull requests são bem-vindos. Para mudanças importantes, por favor, abra um problema primeiro para discutir o que você gostaria de mudar.

Certifique-se de atualizar os testes conforme apropriado.

## Licença
GPL License (enquanto não ficar completo)

## E-mail para contato
Caso tenha interesse em utilizar a ferramenta, entrar em contato comigo para que eu dê continuidade (henriquemauler@gmail.com)

## Possíveis nomes futuros (ignore essa parte)
Aurora, Kyoshi
Mantra, frontera
Koda
Terra Luna
Luma
Hinara
Nara
Nara Luna
Nara Luma
Kemal
Kenai