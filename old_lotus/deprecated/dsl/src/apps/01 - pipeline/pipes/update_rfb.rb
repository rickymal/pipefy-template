load "./apps/#{__FILE__}/main.rb"

AsyncQueue = Pipefy::Builder.new


AsyncQueue.pipeline do |it|
    it.source 'load_enterprises'
    it.source 'load_simple'
    it.source 'load_partners'
    it.source 'load_stablishments'
    it.flow ['transform']
    it.flow ['load']
end

AsyncQueue.template [App]

find_ruby_files_by_path("./services") do |path|
    find_klass_by_path(path) do |klass|
        AsyncQueue.services(klass)
    end
end

find_ruby_files_by_path("./services/#{__FILE__}") do |path|
    find_klass_by_path(path) do |klass|
        AsyncQueue.services(klass)
    end
end

find_ruby_files_by_path("./extensions") do |path|
    find_modules_by_path(path) do |klass|
        AsyncQueue.extensions(klass)
    end
end

find_ruby_files_by_path("./extensions/#{__FILE__}") do |path|
    find_modules_by_path(path) do |klass|
        AsyncQueue.extensions(klass)
    end
end


def run(initial_value)
    pipeline = AsyncQueue.new()
    Async do 
        pipeline.send(initial_value)
    end
end