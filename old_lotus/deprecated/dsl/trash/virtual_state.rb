
require 'pry'
# Criar de uma forma que eu consiga fazer uma pilha!

# Objeto criado com o único propósito de treinar estrutura de dados
# É inútil e gera overengineering. não usar!
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

module VirtualObject
    def self.included(klass)
        klass.attr_accessor :virtual
        klass.define_method 'initialize' do 
            virtual_klass = Class.new(self.class)
            virtual_klass.define_method 'initialize' do 
                init()
            end

            self.virtual = virtual_klass.new()
            if self.respond_to? 'init'
                init()
            end
        end
    end
end


class App
    # include VirtualObject
    attr_accessor :state
    def mod()
        puts @state
    end

    def init()
        @state = 10
    end
end

app = App.new

LightDom.new -> { app } do 
    this.mod()
    
    it.using state: 'open' do
        this.mod()
    end

    it.using state: 'closed' do
        this.mod()

        it.using state: 'internal_closed' do
            this.mod()
        end

        this.mod()
    end

    this.mod()
end


