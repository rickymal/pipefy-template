module Lotus
    module DefaultInitializer
        def _lotus_service_loading(service = {})        
            service.each do |name, srv|
                
              self.singleton_class.attr_accessor name
              self.send("#{name}=", srv)
            end
        end
    end
end