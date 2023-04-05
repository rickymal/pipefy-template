module Env
    class Default
        def initialize(pipes, &blk)
            @pipes = pipes
            # @pipeline = pipeline.build_pipeline()
            pipelines = @pipes.map {|it| it.build_pipeline()}
            @qi = pipelines[0][0]
            @qo = pipelines[-1][-1]
            pipelines.each_cons(2) do |p1, p2|
                Async do 
                    while resp = p1[1].dequeue
                        p2[0].enqueue resp
                    end
                end
            end
        end
        
        def send(data)
            @qi.enqueue data
        end


        def take()
            @qo.dequeue
        end


        def size()
            @qo.size()
        end
    end
end