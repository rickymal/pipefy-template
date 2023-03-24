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
    var = find_ruby_files_by_path './src/pipes', ignore: [__FILE__] do |path|
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

class ServelessAsync
    def initialize()
        @GETS = []
    end

    def add_saas(app)
        # Parei aqiu hermano, fazer o seguinrte
        # Criar o sistema que faz o Pipefy rodar no seu próprio ambiente (considerar apenas Threads e ractor com metodo send e take)
        binding.pry
        @GETS << 

    end

    def call(request)
        request.method # retorna o método
        request.path # retornas as query parameters
        routes, qparams = request.path.split("?")
        query_params = URI.decode_www_form(qparams || '').to_h.map{|k,v| [k.sub('/?', ''), v]}.to_h
        header = request.headers.to_h
        body = JSON.parse(request.read())
        Protocol::HTTP::Response[200, {}, ["Hello World"]]
    end
end


serveless = ServelessAsync.new()
endpoint = Async::HTTP::Endpoint.parse('http://127.0.0.1:3003')
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

        binding.pry
        task.async do  
            server.run()
        end 
        
    end
end

