
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
        binding.pry
    end

    def dispatch_in_ractor1(data)
    end
    

    def dispatch_in_ractor2(data)
    end

end