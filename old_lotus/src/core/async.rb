require_relative 'promises.rb'

module Extensions
    def self.included(base)
      base.extend(ClassMethods)
    end
  
    module ClassMethods
      def singleton_method_added(method_name)
        return if @_async_singleton_method_hook_disabled
  
        original_method = singleton_method(method_name)
  
        @_async_singleton_method_hook_disabled = true
  
        define_singleton_method(method_name) do |*args, &block|
          if Async::Task.current?
            return original_method.call(*args, &block)
          else
            return Promise.new.run do
              Async do |task|
                original_method.call(*args, &block)
                task.children.each(&:wait)
              end
            end
          end
        end
  
        @_async_singleton_method_hook_disabled = false
      end
    end
end
  

module App
    include Extensions

    def self.m1(*args)
        puts "App m1"
        m2
    end

    def self.m2(*args)
        puts "m2"
    end

    def self.m3(*args)
        puts "m3"
    end 
end
  

App.m1.then do |result|
    puts "Result: #{result}"
end
  