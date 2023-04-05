class LightDom
    attr_accessor :this, :state, :it

    def initialize(instance, &blk)
        
        @this = instance.call().dup()
        @actual_state = @this.state
        @it = self
        @stack = []

        self.instance_eval(&blk)
    end

    def using(**parameters, &blk)

        @stack << parameters.map do |attribute, val|
            [ attribute, @this.instance_variable_get("@#{attribute}")]
        end.to_h

        parameters.each do |attribute, val|
            @this.instance_variable_set "@#{attribute}", val
        end
        @it.instance_eval(&blk)
        @stack.pop.each do |attribute, val|
            @this.instance_variable_set "@#{attribute}", val
        end
    end
end
