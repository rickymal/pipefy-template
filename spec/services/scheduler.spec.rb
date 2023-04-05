# spec/services/scheduler_test.rb
require 'spec_helper'

class SchedulerTest < Minitest::Test
  def setup
    @scheduler = Scheduler.new
  end

  def test_can_schedule_an_event
    event_triggered = false

    @scheduler.schedule(0.1) do
      event_triggered = true
    end

    refute event_triggered, "O evento não deve ter sido acionado antes do tempo programado"

    sleep 0.2

    assert event_triggered, "O evento deve ter sido acionado após o tempo programado"
  end
end
