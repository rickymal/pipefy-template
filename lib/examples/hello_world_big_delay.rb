class HelloWithBigDelay
  include Lotus::DefaultInitializer
  extend Lotus::Method::Flow

  def call(data = nil)
    sleep 1
    return 'Hello, world!'
  end
end