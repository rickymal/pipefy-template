# lib/seu_projeto/services/scheduler.rb

require 'rufus-scheduler'

module Lotus
  module Services
    class Scheduler
      attr_reader :scheduler

      def initialize
        @scheduler = Rufus::Scheduler.new
      end

      # Agenda um aplicativo para ser executado em um intervalo específico
      def schedule_interval(container, interval)
        @scheduler.every(interval) do
          container.start
        end
      end

      # Agenda um aplicativo para ser executado em um horário específico
      def schedule_time(container, time)
        @scheduler.at(time) do
          container.start
        end
      end

      # Agenda um aplicativo para ser executado em dias e horários específicos
      def schedule_cron(container, cron_expression)
        @scheduler.cron(cron_expression) do
          container.start
        end
      end

      # Para o agendador e todos os trabalhos agendados
      def stop
        @scheduler.shutdown
      end
    end
  end
end
