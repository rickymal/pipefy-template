module Operator
    module SPDCommons
        def pre_init()
            puts "PRE INICIALIZANDO!"
        end
        
        def init()
            puts "INICIALIZANDO!"
        end
    end
  
    class YAMLLoader
        def initialize(ctx)
        end
    
        def pre
            'oooooi'
        end
    end
end