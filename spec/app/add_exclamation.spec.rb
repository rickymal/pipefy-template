# spec/apps/add_exclamation_test.rb
require 'spec_helper'

class AddExclamationTest < Minitest::Test
  def setup
    @add_exclamation = AddExclamation.new
  end

  def test_adds_exclamation_mark_to_input
    assert_equal 'Hello!', @add_exclamation.call('Hello')
  end
end
