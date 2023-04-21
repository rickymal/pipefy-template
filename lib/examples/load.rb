class Load
    include Lotus::DefaultInitializer
    extend Lotus::Method::Flow 
  
    def call(data = nil)
      return "data: #{data}"
    end
end