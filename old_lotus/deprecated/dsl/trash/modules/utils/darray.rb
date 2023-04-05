require './utils/cycle.rb'

class Darray < Array
    def initialize(size:, batch:, &block)
        @block = block
        @batch = batch
        @_inventory = Concurrent::Array.new(size) { Array.new() }
        @inventory = Cycle.new @_inventory
        @inventory = @_inventory.cycle()
        @array = @inventory.next()
        @mtx = Mutex.new()
        
        @pool = Concurrent::FixedThreadPool.new(size, task_queue_size: 3 * size)
        @cv = Thread::ConditionVariable.new

        if !@block
            raise ArgumentError, "O metodo precisa receber um bloco"
        end
    end

    def get_inventory_size()
        return @_inventory.map {|ctx| ctx.size()}
    end
    
    def dispatch_content()
        
        if @array.size() < @batch 
            return
        end
        
        actual_array = @array
        @array = @inventory.next()
         
        @pool.post do 
            actual_array.each_slice(@batch) do |ctx|
                @block.call(ctx)
            end
            actual_array.clear()
        end
    rescue Concurrent::RejectedExecutionError => error
        
    end

    def <<(val)
        @array << val
        # @mtx.synchronize { dispatch_content() }
        dispatch_content()
        return @array
    end

    def size()
        return @array.size()
    end
    
    def push(*val)
        @array.push(*val)
        @mtx.synchronize { dispatch_content() }
        return @array
    end
    
    def send_remains()

        # Caso existe algum processo pendente
        @pool.shutdown()
        @pool.wait_for_termination()
        
        while @_inventory.any? {|ctx| ctx.size() != 0}
            actual_array = @array
            @array = @inventory.next(@mtx)
    
            actual_array.each_slice(@batch) do |ctx|
                @block.call(ctx)
            end
            actual_array.clear()
        end
    end
end
