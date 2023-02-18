class Cycle
    def initialize(object)
        @size = object.size()
        @idx = 0
        @inventory = object
        @obj = object[@idx]
    end

    def val()
        return @obj
    end

    def next()
        @idx += 1
        if @idx >= @size
            @idx = 0
        end
    end
end