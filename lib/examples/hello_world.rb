class HelloWorld
    include Lotus::DefaultInitializer
    extend Lotus::Method::Flow
  
    def call(data = nil)
      return "Hello, world!"
    end
end