module Env
    module Default
        def self.work(&blk)
            return Async(&blk)
        end
    end
end