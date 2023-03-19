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



App = Davinci.App name: "Dashboard", route: "/root" do |it|

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
        load_application(path) 
    end
end
binding.pry
# Aqui que eu vou construir toda a forma de UX
if Davinci.is_root? App 
    Async do 

        # procura pelo nó filho chamado de 'app' (nome colocado no parâmetro 'name' do objeto Davinci.App)
        app = App.new().find_context_by_name('app')

        Davinci.sequencialize(app['srcs'], app['flws'], app['loaders'])

        app.send 10
        
    end
end