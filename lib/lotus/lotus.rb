# lib/lotus.rb

require_relative 'lotus/app'
require_relative 'lotus/pipefy'
require_relative 'lotus/container'
require_relative 'lotus/services/scheduler'
require_relative 'lotus/services/no_code_service'
require_relative 'lotus/services/http_service'

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
