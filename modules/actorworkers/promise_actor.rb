
class PromisedActor


    def destroy()
        @remote_producer.send nil
        sleep 0.5 until @remote_producer.inspect.include? "terminated"
    end

    # 1. preciso fazer com que o remote retorne uma promise depois
    # 2. Por hora quero apenas o callback em bloco, e testar com vários consumers
    def initialize(sym_klass)
        consumer = Ractor.new do
            while resp = Ractor.receive()
                Ractor.yield resp
            end
        end

        MethodDelegator.new self, :remote do |method, args, kwargs|
            next Concurrent::Future.execute do 
                @remote_producer.send({method:, args:, kwargs:})
                next consumer.take()
            end
        end


        instance = Ractor.make_shareable sym_klass.call().dup()
        @remote_producer = Ractor.new(instance, consumer) do |remote_instance, consumer|

            while resp = Ractor.receive() 
                method, args, kwargs = resp.fetch_values(:method, :args, :kwargs)
                returned_value = remote_instance.send(method, *args, **kwargs)
                if Ractor.shareable? returned_value
                    consumer.send({
                        status: "OK",
                        freezed: false,
                        data: returned_value,
                    })
                else
                    if Ractor.shareable? Ractor.make_shareable(returned_value)
                        consumer.send({
                            status: "OK",
                            freezed: true,
                            data: returned_value,
                        })
                    else
                        consumer.send({
                            status: ":(",
                            data: "Cannot return data of type #{returned_value.class}",
                        })
                    end
                end
            end

            consumer.send nil
        end

    end
end



class App
    
    def initialize()
        @x = 10
    end

    def x()
        @x
    end

    def x=(val)
        @x = val
    end

    def call(hello)
        puts "Helloying"
        return "#{hello} plus 2"
    end
end


# Problemas
# 1. Finalizar o PromisedActor para fazer o teste de desempenho posteriormente.
actor = PromisedActor.new -> { App.new() } 

val = actor.remote.x  
actor.destroy()

# Importante para expor os métodos e assim permitir acessa-los remotamente o Ractor
public 

@arr = 300

def call(message, *args)
    return "ms: #{message} wth #{args} with instance #{@arr}"
end


