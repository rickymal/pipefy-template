class VirtualState
    def initialize(instance)
      @this = instance.call
      @actual_state = @this.get_state
      @it = self
    end
  
    def with(state)
      @this.set_state(state)
      yield
      @this.set_state(@actual_state)
    end
  end
  
  class App
    def initialize
      @state = 10
    end
  
    def mod
      puts @state
    end
  
    def get_state
      @state
    end
  
    def set_state(val)
      @state = val
    end
  end
  

  VirtualState.new -> { App.new } do 
    this.mod()
    it.with 'open' do
        this.mod()
    end

    it.with 'closed' do
        this.mod()
    end

    this.mod()
end