
# [future] Objeto responsável por realizar a integração entre pipelines
class Controller
    def initialize(pipelines)
        # Vamos fazer uma integração entre três pipes, permitindo que um pipe consiga mandar dados para outros 3
        # Contato que estes estejam no mesmo processo

        pklass = pipelines.find_pipe_by_name('update_rfb')

        pklass.attribute_accessor 'p1'
        pklass.send("p1=", pipelines.find_pipe_by_name('p1'))
        
        pklass.attribute_accessor 'p2'
        pklass.send("p2=", pipelines.find_pipe_by_name('p2'))
        
    end
end