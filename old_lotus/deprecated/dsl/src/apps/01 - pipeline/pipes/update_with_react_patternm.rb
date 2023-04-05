load "./apps/#{__FILE__}/main.rb"

# [ ] preciso criar uma classe que seja capaz se montar ela mesma em uma estrutura de pilha

AsyncQueue = Pipefy::Builder.spawn do |this|

    this.template [App]
    
    find_ruby_files_by_path("./services") do |path|
        find_klass_by_path(path) do |klass|
            this.services(klass)
        end
    end
    
    find_ruby_files_by_path("./services/#{__FILE__}") do |path|
        find_klass_by_path(path) do |klass|
            this.services(klass)
        end
    end
    
    find_ruby_files_by_path("./extensions") do |path|
        find_modules_by_path(path) do |klass|
            this.extensions(klass)
        end
    end
    
    find_ruby_files_by_path("./extensions/#{__FILE__}") do |path|
        find_modules_by_path(path) do |klass|
            this.extensions(klass)
        end
    end

    visualize(this)

    # o método tensor cria um children dele mesmo
    p1 = this.tensor()
    p2 = this.tensor()
    p3 = this.tensor()

    sequence(p1, p2, p3)

    # input, output
    import(p1)
    export(p3)

    p1.pipeline do |it|
        it.source 'load_enterprises'
        it.source 'load_simple'
        it.source 'load_partners'
        it.source 'load_stablishments'
    end

    p2.pipeline do |it|
        it.flow ['t1','t2','t3']
        it.flow ['t4','t5','t6']
    end

    p3.pipeline do |it|

    end

    
    
end



def run(initial_value)
    pipeline = AsyncQueue.new()
    Async do 
        pipeline.send(initial_value)
    end
end