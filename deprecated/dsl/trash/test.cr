class VirtualState
    attr_accessor :this, :state, :it
    def initialize(instance, &blk)
        @this = instance.call()
        @actual_state = @this.state
        @it = self
        self.instance_eval(&blk)
    end

    def using(state, &blk)
        @this.state = state
        @it.instance_eval(&blk)
        @this.state = @actual_state
    end
end

class App
    attr_accessor :state
    def mod()
        puts @state
    end

    def initialize()
        @state = 10
    end

    def get_state()
        @state
    end

    def set_state(val)
        @state = val
    end
end

VirtualState.new -> { App.new } do 
    this.mod()
    it.using "open" do
        this.mod()
    end

    it.using "closed" do
        this.mod()
    end

    this.mod()
end