class ContextMapping
    def self.set_block(&block)
      @block = block
    end
  
    def self.get_block
      @block
    end
  
    def self.create_class_with_call
      block = get_block
      klass = Class.new do
        define_method(:initialize) do
          @block = block
        end
  
        define_method(:call) do |*args|
          instance_exec(*args, &@block)
        end
      end
      klass
    end
  end
  
  # Exemplo de uso
  ContextMapping.set_block { |x| x * 2 }
  my_class = ContextMapping.create_class_with_call
  
  my_instance = my_class.new
  result = my_instance.call(5)
  puts result # Output: 10
  