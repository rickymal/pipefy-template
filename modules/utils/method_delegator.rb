# ============== algoritmo de atores mais decente
class MethodDelegator

    def initialize(context, build_method, &blk)
        @context = context
        
        if context.respond_to?(build_method) && block_given?
            raise Exception, "is not possible create an remote method #{build_method} if it already exists!"
        end

        @blk = blk
        auto_delegator = self
        context.define_singleton_method(build_method) { auto_delegator }
    end

    def method_missing(method, *args, **kwargs)
        
        if @blk
            return @blk.call method, args, kwargs
        else
            return @context.send(method, args, kwargs)
        end
    end
end