module Lotus
  module ChainableMethods
    def chain
      ChainProxy.new(self)
    end
  
    class ChainProxy
      def initialize(target)
        @target = target
      end
  
      def method_missing(method_name, *args, &block)
        return super unless @target.respond_to?(method_name)
  
        ancestors = @target.class.ancestors.select { |ancestor| ancestor.instance_methods(false).include?(method_name) }
        ancestors.each do |ancestor|
          ancestor.instance_method(method_name).bind(@target).call(*args, &block)
        end
      end
    end
  end
end