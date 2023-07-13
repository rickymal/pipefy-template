class Transform
    include Lotus::DefaultInitializer
    extend Lotus::Method::Actor
  
    def call(data = nil)
      res = "transforming: #{data}"
      return res
    end
end