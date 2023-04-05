# lib/seu_projeto.rb

require_relative 'seu_projeto/app'
require_relative 'seu_projeto/pipefy'
require_relative 'seu_projeto/container'
require_relative 'seu_projeto/services/scheduler'
require_relative 'seu_projeto/services/no_code_service'
require_relative 'seu_projeto/services/http_service'

module Lotus
  # Classe principal do seu framework
  class Lotus
    def initialize
      # Inicialize os componentes principais do seu framework
      @app = App.new
      @container = Container.new
      @scheduler = Services::Scheduler.new
      @no_code_service = Services::NoCodeService.new
      @http_service = Services::HttpService.new
    end

    # Adicione métodos e lógicas para interagir com os componentes do seu framework
    # e para fornecer uma interface para os usuários do seu framework.
  end
end
