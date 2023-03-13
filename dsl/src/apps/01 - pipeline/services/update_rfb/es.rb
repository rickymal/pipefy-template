require 'elasticsearch'

# Dependencies injection inverted
class Service

    def self.on_load(pipeline)
        pipeline.set_service self
    end

    def on_finish()
    end

end