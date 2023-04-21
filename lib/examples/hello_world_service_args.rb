class HelloWithServiceArgs
    include Lotus::DefaultInitializer
    extend Lotus::Method::Flow
  
    def call(data = nil)
      return "Hello, #{self.print_service.say_name}"
  
    end
end