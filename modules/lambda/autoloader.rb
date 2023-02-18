module Cleanup
    def pre_init()
    end

    def init()
    end

    def post_init()
    end
end

class Autoloader
    def initialize()
        @modules = []
        @binding = nil
    end

    def bind(object)
        @binding = object
    end

    def include(mod)
        @modules << mod
    end

    def load(method, *instances)
       
        @modules = @modules.select {|mod| mod.method_defined?(method)} 
        @modules.each do |mod|
            # puts "importando #{mod}"
            # binding.pry
            # # pode ser utilizado o unbind também
            # instance.singleton_class.include mod

            # if instance.method(method).super_method().nil?
            #     procedure = instance.method(method)
            # else
            #     procedure = instance.method(method).super_method()
            # end

            # procedure.call()
            # # instance.send(method)
            # instance.singleton_class.include Cleanup


            mod.instance_method(method).bind(instances.first()).call(*instances)
        end

    rescue Exception => error
        binding.pry
    end
end