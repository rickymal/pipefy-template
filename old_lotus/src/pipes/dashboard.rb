require 'pry-stack_explorer'

require './src/utils/utils.rb'
require './src/utils/davinci.rb'

# Sets the initial number of heap slots.
ENV['RUBY_GC_HEAP_INIT_SLOTS'] = '10000'

# Sets the minimum number of heap slots to be maintained.
ENV['RUBY_GC_HEAP_FREE_SLOTS'] = '4096'

# Sets the factor for heap growth.
ENV['RUBY_GC_HEAP_GROWTH_FACTOR'] = '1.8'

# Sets the maximum number of heap slots that can be added in a single growth step.
ENV['RUBY_GC_HEAP_GROWTH_MAX_SLOTS'] = '0'

# Sets the factor for triggering a full garbage collection when the number of old objects increases.
ENV['RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR'] = '2.0'

# Sets the allocation limit for triggering garbage collection.
ENV['RUBY_GC_MALLOC_LIMIT'] = '8000000'

# Sets the maximum allocation limit for triggering garbage collection.
ENV['RUBY_GC_MALLOC_LIMIT_MAX'] = '16000000'

# Sets the growth factor for the allocation limit.
ENV['RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR'] = '1.4'

# Sets the old object allocation limit for triggering garbage collection.
ENV['RUBY_GC_OLDMALLOC_LIMIT'] = '16000000'

# Sets the maximum old object allocation limit for triggering garbage collection.
ENV['RUBY_GC_OLDMALLOC_LIMIT_MAX'] = '32000000'

# Sets the growth factor for the old object allocation limit.
ENV['RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR'] = '1.2'

require './src/envs/default.rb'

application = App name: "Dashboard", route: "/root" do |it|

    

    find_ruby_files_by_path './src/extensions' do |path|
        
        get_constants_by_path(path) do |_, mdl|
            it.plug mdl
        end
    end

    find_ruby_files_by_path './src/template' do |path|
        get_constants_by_path(path) do |_, mdl|
            it.template mdl
        end
    end

    find_ruby_files_by_path './src/services' do |path|
        get_constants_by_path(path) do |file, srv|

            it.use file => srv
        end
    end
    
    # Carrega todo conteudo da pasta pipes excluindo-se
    var = find_ruby_files_by_path './src/pipes', ignore: [__FILE__, 'server.rb'] do |path|
        pp path
        load_application(path) 
    end
    
end
require 'json'
require 'async'
require 'async/http/internet'
require 'async'
require 'async/http/server'

require 'async'
require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/http/protocol/response'


require 'uri'

app = lambda do |request|

    request.method # retorna o método
    request.path # retornas as query parameters
    query_params = URI.decode_www_form(request.path || '').to_h.map{|k,v| [k.sub('/?', ''), v]}.to_h
    body = JSON.parse(request.head())
	Protocol::HTTP::Response[200, {}, ["Hello World"]]
end

# class Contente
#     extend Davinci::Hybrid

#     def m1()
#     end
# end

def generate_token(length = 32)
    charset = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    token = Array.new(length) { charset.sample }.join
    return token
end

require 'async/http/internet'
require './src/core/promises.rb'
require 'async'
require 'async'
require 'async'


class Facade
    def send()
    end

    def size()
    end

    def take()
    end
end

class ServelessAsync
    def initialize()
        @APPLICATIONS = {}
        @RUNNING_APPS = {}
        @GETS = Hash.new()
        @tokens = {}
    end

    def add_saas(app)
        # Parei aqiu hermano, fazer o seguinrte
        # Criar o sistema que faz o Pipefy rodar no seu próprio ambiente (considerar apenas Threads e ractor com metodo send e take)
        # ctx = app[:klass].new(app[:env]).build_pipeline()
        

        # # A partir de agora, registramos os nomes, mas precisaremos dar o fork para que consigamos utilizar a ferramenta
        # if app.fetch(:name)&.empty?
        #     @APPLICATIONS[app.fetch(:name)] = app
        # end

        # @GETS[app.fetch(:route)] = ctx
        @APPLICATIONS[app.fetch(:route)] = app
    end

    def call(request)

        # Realizar a conversão dos dados
        request.method # retorna o método
        request.path # retornas as query parameters        
        routes, qparams = request.path.split("?")
        routes = routes.split("/").join '/'
        query_params = URI.decode_www_form(qparams || '').to_h.map{|k,v| [k.sub('/?', ''), v]}.to_h
        header = request.headers.to_h
        body = JSON.parse(request.read()) if !request.body.nil?

        if request.method == 'FORK'
            resp = generate_token()
            ctx = @APPLICATIONS[routes][:klass].new @APPLICATIONS[routes][:env]
            
            if query_params['enviroment'] == 'task'

                # Como eu vou fazer aqui?
                app = ctx.build_pipeline()
                 

                @RUNNING_APPS[resp] = app 
            end

            

            if query_params['enviroment'] == 'container'
                container = Async::Container.new
                input, output = Async::IO.pipe
                input_, output_ = Async::IO.pipe
                sleep 2
                
                process = container.spawn name: "Processo filho" do |instance|
                    Async do
                        print "Iniciando processo!"
                        app = ctx.build_pipeline()
                        @RUNNING_APPS[resp] = app
                        stream_getter = Async::IO::Stream.new(input)
                        stream_setter = Async::IO::Stream.new(output_)
                
                        while message = stream_getter.gets
                            data = Marshal.load(message)
                            sleep 2
                            puts "Recebido no processo: #{data}".center(80, '-')
                            stream_setter.puts Marshal.dump("Recebido hermano!")
                        end
                    end
                end
                
                stream_getter = Async::IO::Stream.new(input)
                stream_setter = Async::IO::Stream.new(output)
                stream_getter_ = Async::IO::Stream.new(input_)
                stream_setter_ = Async::IO::Stream.new(output_)
                
                task = Async do
                    while messge = stream_getter_.gets
                        sleep 2
                        puts "RETORNADO: #{Marshal.load(messge)}"
                    end
                end
                
                binding.pry
                stream_setter.puts Marshal.dump(query_params)
                
                @RUNNING_APPS[resp] = Facade.new stream
                
                
            end


            return Protocol::HTTP::Response[200, {}, [{
                type: query_params['enviroment'],
                tid: resp,
            }.to_json()]]

        end

        if request.method == 'POST'
            tid = header['tid'].first()
            
            @RUNNING_APPS[tid].send(query_params)

            # @GETS[routes].send(query_params)
            if (!header['token-request'].nil? && header['token-request'].first() == 'true') || header['callback-endpoint']
                if header['token-request'].first() == 'true'
                    resp = generate_token()
            
                    @tokens[resp] = @RUNNING_APPS[tid]
              
                    # @tokens[resp] = Promise.run do 
                    #     process = 
                    #     resp = process.take()
                    #     next lambda { resp }
                    #     # @RUNNING_APPS[tid].take()
                    # end
                end

                if header['callback-endpoint']
                    endpoint = header['callback-endpoint'].first()
                    client = Async::HTTP::Internet.new
                    
                    resp = ''

                    headers = { 'Content-Type' => 'application/json' }
                    batch = header['batch'][0].to_i
                    # batch = 20

                    Promise.run do 
                        results = [@RUNNING_APPS[tid].size(), batch].min().times.map do
                            @RUNNING_APPS[tid].take()
                        end
                        next results
                    end.then do |results|
                        # Parei aqui, no outro lado não recebo .json algum
                        body = JSON.generate(results)
                        response = client.post(endpoint, headers, body)
                    end

                    return Protocol::HTTP::Response[200, {}, [{
                        status: 'required-callback',
                        endpoint: endpoint
                    }.to_json()]]
                end


                return Protocol::HTTP::Response[200, {}, [resp]]
            end


            return Protocol::HTTP::Response[200, {}, [@RUNNING_APPS[tid].take().to_s()]]
            # return Protocol::HTTP::Response[200, {}, [@GETS[routes].take().to_s()]]
            
            # Protocol::HTTP::Response[200, {}, Enumerator.new do |yld|
            #     yld << {pipeline: data}.to_json()
            # end]
        elsif request.method == 'GET' 
            batch = query_params['batch'].to_i
            if query_params['token'].nil?
                return Protocol::HTTP::Response[400, {}, ["coloca o token em query params meu/minha patrão/patroa"]]
            end
            
            results = [@tokens[query_params['token']].size(), batch].min().times.map do
                @tokens[query_params['token']].take()
            end
            return Protocol::HTTP::Response[200, {}, [results.to_json()]] 
            # return Protocol::HTTP::Response[200, {}, [@tokens[query_params['token']].take().to_h.to_json()]] 
        end
    end
end


serveless = ServelessAsync.new()
endpoint = Async::HTTP::Endpoint.parse('http://127.0.0.1:3004')
server = Async::HTTP::Server.new(
    serveless, 
    endpoint
)

# Aqui que eu vou construir toda a forma de UX
if Davinci.is_root? application 
    Async do |task|
        # procura pelo nó filho chamado de 'app' (nome colocado no parâmetro 'name' do objeto Davinci.App)
        apps = application.new()

        apps.each do |app|
            serveless.add_saas(app) 
        end

        task.async do  
            server.run()
        end 
        
    end
end

