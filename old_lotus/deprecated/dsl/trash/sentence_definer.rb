class SomeItClass
    def draw()
    end
end

class SomeAtClass
    def consult()
    end
end

class SomeOtClass
    def get()
    end
end

require 'pry-stack_explorer'
it = SomeItClass.new
at = SomeAtClass.new
ot = SomeOtClass.new

class MyObject
    def initialize(*args)
      @delegates = args
    end
    
    def method_missing(method_name, *args, &block)
      @delegates.each do |delegate|
        if delegate.respond_to?(method_name)
          return delegate.send(method_name, *args, &block)
        end
      end
      super
    end
    
    def respond_to_missing?(method_name, include_private = false)
      @delegates.any? { |delegate| delegate.respond_to?(method_name) } || super
    end
  end
  

cnpj_consult = MyObject.new(it, at, ot) do
  draw do |drawer|
    consult do |opt|
      get do |up|
        
        # ...
      end
    end
  end
end
