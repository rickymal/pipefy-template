class Extract
    include Lotus::DefaultInitializer
    extend Lotus::Method::Stream
  
    def call(data = nil)
      data.times do |yld|
        yield yld
      end
    end
end