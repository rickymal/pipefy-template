class HelloWithBigDelayAndError
    include Lotus::DefaultInitializer
    extend Lotus::Method::Flow
  
    def call(data = nil)
      sleep 1
      raise CustomException, "Um erro personalizado"
    end
end