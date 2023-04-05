module Env
    class Actor
        def initialize(pipes, &blk)
            @pipes = pipes
            # @pipeline = pipeline.build_pipeline()
            binding.pry
            pipes = Ractor.make_shareable(pipes)

            ractor = Ractor.new() do 
                pipudo = Ractor.receive()
                pipudo.map {|it| it.build_pipeline()}
            end

            ractor.send(pipes, move: true)

            binding.pry

            @ractor = Ractor.new(pipes) do |pipes|
                pipelines = pipes.map {|it| it.build_pipeline()}
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
        end

        def send(data)
            @ractor.send data
        end
    
    
        def take()
            @ractor.take()
        end
    end
end

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
end