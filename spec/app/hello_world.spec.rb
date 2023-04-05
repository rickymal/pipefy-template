# spec/apps/hello_world_test.rb
require 'spec_helper'

class HelloWorldTest < Minitest::Test
  def setup
    @hello_world = HelloWorld.new
  end

  def test_prints_input_with_greeting
    assert_output("Hello, World!\n") do
      @hello_world.call('World')
    end
  end
end
