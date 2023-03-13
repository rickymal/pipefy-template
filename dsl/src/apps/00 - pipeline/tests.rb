
# Template
PipeDSL.with App do |it|

    # Queue, dequeue pattern
    it.source 'load_enterprises'
    it.source 'load_stablisments'
    it.source 'load_partners'

    # Send, take pattern
    it.with Default do |it|
        it.flow 't1'
        it.flow 't2'
        it.flow 't3'
    end

    it.with Ractor do |it|
        it.flow 't4'
        it.flow 't5'
        it.flow 't6'
    end
end

module App


    def load_enterprises(interval)
        10.times do |yld|
            yield "henrique"
        end
    end
    
    def load_stablisments(enterprise)
        20.times do 
            yield "#{enterprise} mauler"
        end
    end
    
    def load_partners(stablisment)
        30.times do 
            yield "#{stablisment} borges"
        end
    end
    
    def run(document)
        @hfb << document
    end
    
    def dispatch_data(batch)
        sleep 10
        return batch[0]
        binding.pry
    end

    def dispatch_in_ractor1(data)
    end
    

    def dispatch_in_ractor2(data)
    end

end