class Promise
    attr_reader :result, :status

    def initialize(&blk)
      @task = nil
      @result = nil
      @error = nil
      @status = :initialized

      if block_given?
        self.run(&blk)
      end
    end

    def self.run(&blk)
      promise = self.new()
      promise.run(&blk)
      return promise
    end

    def to_h
      {
        "status" => @status,
        "result" => @result,
        "error" => @error
      }
    end

    def run(&block)
      raise "Promise already running" if @task

      @task = Async do |task|
        @status = :running

        begin
          @result = block.call(task)
          @status = :success
        rescue Exception => e
          @error = e
          @status = :error
        end
      end

      self
    end

    def await()
      @task.wait()
    end

    def then(&block)
      raise "Promise not running" unless @task

      @task.wait

      if @error
        @status = :error
        raise @error
      else
        @status = :success
        block.call(@result) if block_given?
      end
    end
end