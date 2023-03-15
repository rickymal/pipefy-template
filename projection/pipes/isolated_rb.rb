module Brr
    include Pipefy::AsyncMethods

    def m1()
    end

    def run(data)

        # A chamada interna não é assíncrona
        m1()
    end
    
end


module App
    include Pipefy::ETL

    def extract()
        @brr = Brr.new()
    end

    def transform()
        # A chamada externa é assíncrona
        promise = @brr.run().await()
    end

    def load()
    end
end

App.new()