
class Elasticsearch
    def on_load(ctx)
    end
end

class Mongodb
    def on_load(ctx)
    end
end

module SPDCommons
    def init()
        puts 'inicializando!'
        sleep 1
    end
end

class App
    def self.new(services, extensions)
        services.each do |attr, service|
            self.attr_accessor attr
            self.send("#{attr}=", service)
        end

        instance = self.allocate()

        extensions.each do |mdl|
            mdl.instance_method('init').bind(instance).call()
        end
    end


    def run()


    end
    

end
App.new(
    [
        Elasticsearch.new,
        Mongodb.new,
    ],
    [
        SPDCommons
    ]
).run()

