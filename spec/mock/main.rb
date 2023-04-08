require_relative '../../lib/lib.rb'

class HelloWorld < Lotus::Activity::Job
    def call(name:)
      "Hello World #{name}!"
    end
  end
  
  class SayHello < Lotus::Activity::Job
    def call()
      @name
    end
  
    def on_load()
      @name = "Hello"
    end
  end
  
  class SayWorld < Lotus::Activity::Job
    def call()
      @name
    end
  
    def on_load()
      @name = "World"
    end
  end
  
  class YamlLoader < Lotus::Activity::Service
    attr_reader :yaml
  
    def on_load()
      @yaml = []
    end
  end
  
  class RemoteService < Lotus::Activity::Service
    def on_load(activity)
      @remote_service = self.yaml_loader.yaml
      @activity = activity
    end
  end
  
  class Journey < Lotus::Activity::Job
  end
  
  class N1 < Lotus::Activity::Job
    def call(name:)
      "Hello,"
    end
  end
  
  class N2 < Lotus::Activity::Job
    def call(name:)
      " World"
    end
  end
  
  class N3 < Lotus::Activity::Job
    def call(name:)
      "Henrique"
    end
  end
  
  
  def container()
    return Lotus::App::Container.create()
  end
  