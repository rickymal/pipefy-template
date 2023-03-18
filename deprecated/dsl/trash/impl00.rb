module Pipe

    # Quando o Job tem a capacidade de puxar sua própria fonte de dados
    def extract()
    end

    # Quanto o Job recebe uma requisição para processar
    def source()
    end

    # Realizar uma transformação 
    def t1()
    end
    
    # Realizar uma transformação 
    def t1()
    end

    # Onde descarregará os dados
    def load()
    end

    # Manda um feedback do pipe
    def feedback()
    end
    
    # Manda um feedback do pipe
    def report()
        return {
            example: 10
        }
    end
end




module Speedio
    module ElasticClient
        def pre_init(klass)
        end

        # Conterá toda a autenticação para o uso do elasticsearch de 'dev' e de 'prod'
        def init(klass, instance)
            number = 10
            def instance.get_elastic_client = number
        end

        def post_init(instance)
        end
    end
end

module Authentication
    module SPDCommons
        def init(klass, instance)
            @config = []
        end
    end
end


# PI, PX (Programming Interface, Programming Experience)
# Camada de complexidade, para possiveis adaptações

# Objetivos
# 1. Permitir criar facilmente jobs para algum tipo de processamento

# 3. Permitir uso de arquitetura lambda
# 4. permitir com que exista relatórios a serem extraidos constantemente
# 5. Permitir com que a aplicação consiga renderizar uma tela para atualizarmos os dados
# 6. Ser capaz de criar os processos, definir data de inicio e fim
# 7. Ser capaz de gerenciar o uso de memória presente no servidor   


# 0. Exemplo de estrutura

Kod = Kodiak.new [Speedio::Elasticsearch, Authentication::SPDCommons] do
    # klass, wk (criados internamente)
    # BigObject, objeto criado a partir de um lambda com o modulo ou classe inserido (neste caso, modulo Pipe em Job.from(Pipe))
    instance = BigObject.new()

    # Cria uma instancia de pipeline para ser utilizado
    pipe = Worker.create_pipeline()

    # Cria a sequencia junto com os workers que irão trabalhar
    # Como posso definir o que será utilizado e como, como criar um lambda com isso?
    pipe.source(OnDemmandETL, instance.method(:source)) do
        it.render :display
    end

    # Como garantir o acesso a web desses dados aqui?
    pipe.source(StreamELT, instance.method(:extract)) 

    pipe.flow(Darray.new 10, 10, instance.method(:t1), :hfb)
    pipe.flow(Darray.new 10, 10, instance.method(:t1), :hfb)

    pipe.flow(nil, instance.method(:load))
    

    pipe.watch :feedback
end



# 1. Permitir criar facilmente jobs para algum tipo de processamento
JobBuilder = Kodiak.new nil, [Speedio::Elasticsearch, Authentication::SPDCommons] do
    # klass, wk (criados internamente)
    # BigObject, objeto criado a partir de um lambda com o modulo ou classe inserido (neste caso, modulo Pipe em Job.from(Pipe))
    instance = klass.new()

    pipe = Worker.create_pipeline()
    pipe.source(OnDemmandETL, instance.method(:run))
end

class Job < JobBuilder

    def initialize()
    end

    def on_timeout()
        puts "Infelizmente demorou demais"
    end

    def on_finish()
    end

    def on_init()
    end
end

job = Job.new()

job.run("Um texto para ser processado de forma assíncrona", timeout: 1.hour)


# 2 e 3. Permitir o uso de ETL de forma simples (apenas com as threads classicas)
ETLBuilder = Kodiak.new Pipe, [Speedio::Elasticsearch, Authentication::SPDCommons] do

    # klass, wk (criados internamente)
    # BigObject, objeto criado a partir de um lambda com o modulo ou classe inserido (neste caso, modulo Pipe em Job.from(Pipe))
    instance = klass.new()

    # Cria uma instancia de pipeline para ser utilizado
    pipe = Worker.create_pipeline()

    # Cria a sequencia junto com os workers que irão trabalhar
    # Como posso definir o que será utilizado e como, como criar um lambda com isso?
    pipe.source(OnDemmandETL, instance.method(:source)) do
        it.render :display
    end

    # Como garantir o acesso a web desses dados aqui?
    pipe.source(StreamELT, instance.method(:extract)) 

    pipe.flow(Darray.new 10, 10, instance.method(:t1), :hfb)
    pipe.flow(Darray.new 10, 10, instance.method(:t1), :hfb)

    pipe.flow(nil, instance.method(:load))
    
end

class ETL < ETLBuilder
end

etl = ETL.new()

etl.run(timeout: 1.hour())
# ou 
etl.send('DATA', timeout: 1.hour())


# 4. permitir com que exista relatórios a serem extraidos constantemente
ETLBuilder = Kodiak.new Pipe, [Speedio::Elasticsearch, Authentication::SPDCommons] do

    # klass, wk (criados internamente)
    # BigObject, objeto criado a partir de um lambda com o modulo ou classe inserido (neste caso, modulo Pipe em Job.from(Pipe))
    instance = klass.new()

    # Cria uma instancia de pipeline para ser utilizado
    pipe = Worker.create_pipeline()

    # Cria a sequencia junto com os workers que irão trabalhar
    # Como posso definir o que será utilizado e como, como criar um lambda com isso?
    pipe.source(OnDemmandETL, instance.method(:source)) do
        it.render :display
    end

    # Como garantir o acesso a web desses dados aqui?
    pipe.source(StreamELT, instance.method(:extract)) 

    pipe.flow(Darray.new 10, 10, instance.method(:t1), :hfb)
    pipe.flow(Darray.new 10, 10, instance.method(:t1), :hfb)

    pipe.flow(nil, instance.method(:load))
    
end

class ETL < ETLBuilder

    def report(instance)
        instance.report()
    end
end

etl = ETL.new()

etl.run(timeout: 1.hour())
# ou 
etl.send('DATA', timeout: 1.hour())
etl.send('DATA', timeout: 1.hour())
etl.send('DATA', timeout: 1.hour())
etl.send('DATA', timeout: 1.hour())

etl.extract_report()



# 5. Permitir com que a aplicação consiga renderizar uma tela para atualizarmos os dados
ETLBuilder = Kodiak.new Pipe, [Speedio::Elasticsearch, Authentication::SPDCommons] do

    # klass, wk (criados internamente)
    # BigObject, objeto criado a partir de um lambda com o modulo ou classe inserido (neste caso, modulo Pipe em Job.from(Pipe))
    instance = klass.new()

    # Cria uma instancia de pipeline para ser utilizado
    pipe = Worker.create_pipeline()

    # Cria a sequencia junto com os workers que irão trabalhar
    # Como posso definir o que será utilizado e como, como criar um lambda com isso?
    pipe.source(OnDemmandETL, instance.method(:source)) do
        it.render :display
    end

    # Como garantir o acesso a web desses dados aqui?
    pipe.source(StreamELT, instance.method(:extract)) 

    pipe.flow(Darray.new 10, 10, instance.method(:t1), :hfb)
    pipe.flow(Darray.new 10, 10, instance.method(:t1), :hfb)

    pipe.flow(nil, instance.method(:load))
    
end

class ETL < ETLBuilder

    def report(instance)
        instance.report()
    end

    def render()
        return Vue.render()
    end
end

etl = ETL.new()

etl.run(timeout: 1.hour())
# ou 
etl.send('DATA', timeout: 1.hour())
etl.send('DATA', timeout: 1.hour())
etl.send('DATA', timeout: 1.hour())
etl.send('DATA', timeout: 1.hour())

etl.extract_report()

etl.render()

# 6. Ser capaz de criar os processos, definir data de inicio e fim (PARA GERENCIAR MULTIPLOS PROCESSOS)
# e
# 7. Ser capaz de gerenciar o uso de memória presente no servidor   
OneJobBuilder = Kodiak.new nil, [Speedio::Elasticsearch, Authentication::SPDCommons] do
    # klass, wk (criados internamente)
    # BigObject, objeto criado a partir de um lambda com o modulo ou classe inserido (neste caso, modulo Pipe em Job.from(Pipe))
    instance = klass.new()

    pipe = Worker.create_pipeline()
    pipe.source(OnDemmandETL, instance.method(:run))
end
AntoherJobBuilder = Kodiak.new nil, [Speedio::Elasticsearch, Authentication::SPDCommons] do
    # klass, wk (criados internamente)
    # BigObject, objeto criado a partir de um lambda com o modulo ou classe inserido (neste caso, modulo Pipe em Job.from(Pipe))
    instance = klass.new()

    pipe = Worker.create_pipeline()
    pipe.source(OnDemmandETL, instance.method(:run))
end

class Job1 < JobBuilder

    def set_timeout(actual_time, timeout = 1.hour)
        return actual_data + timeout
    end

    def on_timeout()

    end
end

class Job2 < AntoherJobBuilder

    def on_timeout()

    end
end

# Colocar na ordem de importância
MainJob = Kodiak.compose Job1.new(), Job2.new()

class App < MainJob
end

App.memory_usage 0.7
App.cpu_loading [15, 25]
App.run()



# https://socketry.github.io/async/guides/event-loop/index.html
# https://socketry.github.io/async/guides/getting-started/index.html
# https://www.reddit.com/r/ruby/comments/qj4s94/async_ruby/
# https://socketry.github.io/async/
# https://github.com/socketry/async-io
# https://github.com/kurocha/async