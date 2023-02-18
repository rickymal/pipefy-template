
class CBActor

    def destroy()
        @remote_producer.send nil
        sleep 0.5 until @remote_producer.inspect.include? "terminated"
    end

    def call(*args, **kwargs)
        @remote_producer.send({args:, kwargs:})
    end

    def initialize(sym_klass, batch = nil, &blk)
        if block_given?
            consumer = Ractor.new do
                while resp = Ractor.receive()
                    Ractor.yield resp
                end
            end

            Thread.new do 
                while resp = consumer.take()
                    blk.call resp
                end
            end

            instance = Ractor.make_shareable sym_klass.call().dup()
            @remote_producer = Ractor.new(instance, batch, consumer) do |remote_instance, batch, consumer|
                populate = []
                while resp = Ractor.receive() 
                    args, kwargs = resp.fetch_values(:args, :kwargs)
                    returned_value = remote_instance.call(*args, **kwargs)

                    if !batch.nil? && populate.size() < batch
                        populate << returned_value
                        next
                    elsif !batch.nil? && populate.size() >= batch
                        obj_dump = populate
                    elsif batch.nil?
                        obj_dump = returned_value
                    end


                    if Ractor.shareable? obj_dump
                        consumer.send({
                            status: "OK",
                            freezed: false,
                            data: obj_dump,
                        })
                    else
                        if Ractor.shareable? Ractor.make_shareable(obj_dump)
                            consumer.send({
                                status: "OK",
                                freezed: true,
                                data: obj_dump,
                            })
                        else
                            consumer.send({
                                status: ":(",
                                data: "Cannot return data of type #{obj_dump.class}",
                            })
                        end
                    end
                    populate = []
                end
            end
        end
    end
end

public def call(message)
    return "#{message} + 2"
end


# Problemas
actor = CBActor.new -> { self }, 5 do |it|
    it => {status:, freezed:, data:} 
    puts "Worked #{it} with #{data.size()}"
end

actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.call("hello") 
actor.destroy()