module Lotus
  class Container
    attr_accessor :name
    attr_reader :app
    @@applications = {}

    def self.info(*informations)
      @@applications
    end

    def initialize(app = Lotus::Application)
      @app = app
      @activities = []
    end

    def self.clear_application_info()
      @@applications = {}
    end

    def parameters()
      binding.pry
    end

    def pipefy(element, executor, **services)
      if element.is_a? Hash
        klass = element.fetch(:obj).dup()
        invoker = element.fetch(:pipe_method)
        if !klass.instance_methods.include? invoker.to_sym
          raise Exception, "the method #{invoker} was not created in class pipeline"
        end
        klass.alias_method 'call', invoker
        
        element = klass
      end

      @activities << [element, executor, services]
    end

    def get_activities()
      return @activities.map {|it| it[0]}
    end

    def new(services = [], &blk)
      # Atualize @@applications cada vez que uma nova aplicação for criada
      app_instance = @app.new(@activities, services, &blk)
      app_name = @name.dup

      if @@applications[app_name].nil?
        @@applications[app_name] = {
          'applications' => {}
        }
      end

      app_instance_id = "#{app_name} <##{@@applications[app_name]['applications'].size + 1}>"
      @@applications[app_name]['applications'][app_instance_id] = 'running'

      # Adicione um método update_status na instância da aplicação
      app_instance.define_singleton_method(:update_status) do |status|
        @@applications[app_name]['applications'][app_instance_id] = status
      end

      # Adicione um método update_status na instância da aplicação
      
      # app_instance.define_singleton_method(:throw_pipeline) do |exception|
      #   pp 'hello'
      #   
      #   self.throw_error(exception)
      # end

      return app_instance
    end
end
end