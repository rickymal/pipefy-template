# lib/seu_projeto/app/pipefy.rb

module Lotus
    module App
      class Pipefy
        def initialize
          @stages = []
        end
  
        # Adiciona uma etapa ao pipeline
        def add_stage(stage)
          @stages << stage
        end
  
        # Retorna todas as etapas do pipeline
        def stages
          @stages
        end
  
        # Remove uma etapa específica do pipeline
        def remove_stage(stage)
          @stages.delete(stage)
        end
      end
    end
  end
  