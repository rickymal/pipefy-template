require 'pry'

module App
    def load_enterprises(input = nil)
        yield "data1"
        yield "data2"
        yield "data3"
    end

    def load_stablisments(data)
        yield "data4 with #{data}"
        yield "data5 with #{data}"
        yield "data6 with #{data}"
    end

    def load_partners(data)
        yield "data7, #{data}"
        yield "data8, #{data}"
        yield "data9, #{data}"
    end

    def t1(data)
        puts "processando t1: #{data}"
        return data
    end
    
    def t2(data)
        puts "processando t2: #{data}"
        return data
    end
    
    def t3(data)
        puts "processando t3: #{data}"
        return data
    end

    def t4(data)
        puts "processando t4: #{data}"
        return data
    end
    
    def t5(data)
        puts "processando t5: #{data}"
        return data
    end
    
    def t6(data)
        puts "processando t6: #{data}"
        return data
    end
end

module Example
    def draw_pipeline(dsl)
        source 'load_enterprises'
        source 'load_stablisments'
        source 'load_partners'
        flow ['t1', 't2', 't3']
        actor ['t4', 't5', 't6']
    end
end




require_relative "utils/pipefy.rb"
require_relative "utils/operators.rb"

pipe = Pipefy.new(
    App,
    drawer: Example,
    services: [Operator::SPDCommons],
    extensions: {
        yml: Operator::YAMLLoader
    }
)
Async do |it|

    ctxi, ctxo = pipe.build_pipeline()
    ctxi.enqueue 100
    sleep 1
    puts ctxo.dequeue
    binding.pry
end
  