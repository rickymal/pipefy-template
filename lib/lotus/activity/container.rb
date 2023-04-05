# lib/seu_projeto/app/container.rb

module Lotus
    module App
      class Container
        attr_accessor :application, :services, :children
  
        def initialize(application, services = [])
          @application = application
          @services = services
          @children = []
        end
  
        # Adiciona um serviço ao container
        def add_service(service)
          @services << service
        end
  
        # Remove um serviço específico do container
        def remove_service(service)
          @services.delete(service)
        end
  
        # Adiciona um aplicativo filho ao container
        def add_child(child)
          @children << child
        end
  
        # Remove um aplicativo filho específico do container
        def remove_child(child)
          @children.delete(child)
        end
  
        # Inicializa o aplicativo e os serviços
        def start
          # Inicializa o aplicativo
          @application.start
  
          # Inicializa os serviços
          @services.each { |service| service.start }
        end
      end
    end
  end
  