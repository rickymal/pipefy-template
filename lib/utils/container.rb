module Lotus
  class Container
    attr_accessor :name
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

    def pipefy(element, executor, **services)
      @activities << [element, executor, services]
    end

    # def new(services = [], &blk)
    #   @app.new(@activities, services, &blk)
    # end

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