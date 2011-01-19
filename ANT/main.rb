require 'gp'
require 'myfunction'

generations = 200

Gp.set_params({
  :population => 2048, 
  :parsimony_factor => 0.000001,
  :use_adf => true,
  :adf_num => 1,
  :adf_arity => 2,
})

gpsys = Gp::GpSystem.new(MyFunction.new())
gpsys.start(generations)
