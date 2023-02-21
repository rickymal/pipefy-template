# Kenai, Koda
# Kodiak
# Kai
# Kota
# Kael
# Kieran
# Kaelin
# Kyler
# Kian
# Kairo
# Kaleo
# Koa
# Kato
# Karter
# Kamden
# Keaton
# Kellan
# Kasey
# Kameron
# Kade
# Kaleb
# Testes
# Sitka
# Davinci

report = [] << ["interval", "simple", "async1","async2"]

[2, 1, 0.5, 0.25, 0.125,].each do |interval|

    $sleeper = interval
    puts "sleeper: #{interval}"
    sleep 2
    
    module Pipe
        
        def extract()
            10.times do |yld|
                sleep $sleeper
                yield yld
            end
        end
    
        def transform(data)
            sleep $sleeper
            @hfb << data * 100
        end
        
        def load(datas)
            sleep $sleeper
            
        end
    end
    
    benchs = {}
    
    # r1.1 Modelo mais simples
    klass, *args = [Lambda, Pipe, Extension::ARGVLoader]
    
    obj = klass.new *args
    
    obj_builded = obj.build() do 
        @hfb = Darray.new size: 10, batch: 10 do |batch|
            self.load(batch)
        end
    end
    
    
    benchs['simple'] = Benchmark.measure do
        obj_builded.extract() do |data|
            obj_builded.transform(data)
        end
    end.real()
    
    
    # r1.2 modelo utilizando chamadas assíncronav

    pl = Concurrent::CachedThreadPool.new()
    
    obj_builded = obj.build() do 
        @hfb = Darray.new size: 10, batch: 10 do |batch|
            self.load(batch)
        end
    end
    
    
    
    Async do |task|
        ch = Concurrent::Promises::Channel.new 10

        benchs['async'] = Benchmark.measure do
            task.async do
                obj_builded.extract() do |content|
                    pp 'extraindo'
                    ch.push content
                end
        
                ch.push nil
            end
        
            while resp = ch.pop()
                pp 'transform'
                obj_builded.transform(resp)
            end
        end.real()
    end
    
    # r1.3 modelo utilizando chamadas assíncron de oturo jeito
    
    obj_builded = obj.build() do 
        @hfb = Darray.new size: 10, batch: 10 do |batch|
            self.load(batch)
        end
    end
    ch = Concurrent::Promises::Channel.new 10
    pl = Concurrent::CachedThreadPool.new()
    
    puts "part 2"
    benchs['async 2'] = Benchmark.measure do
        task = Async do |task|
            task.async do
                obj_builded.extract() do |content|
                    ch.push content
                end
        
                ch.push nil
                ch.push nil
                ch.push nil
            end
    
            task.async do 
                while resp = ch.pop()
                    obj_builded.transform(resp)
                end
            end
        
            task.async do 
                while resp = ch.pop()
                    obj_builded.transform(resp)
                end
            end
        
            task.async do 
                while resp = ch.pop()
                    obj_builded.transform(resp)
                end
            end
        end
    
        task.wait()
    end.real()

    
    puts "report".center(80, '-')
    binding.pry
    report << [$sleeper, *benchs.values()]
end
binding.pry