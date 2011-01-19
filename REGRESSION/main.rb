require 'gp'
require 'myfunction'

generations = 4

Gp.set_params({
  :population => 1024, 
})

gpsys = Gp::GpSystem.new(MyFunction.new())
gpsys.start(generations)

#fitness_cases_table = 
#  [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
#fitness_cases_table_out = 
#  [0.0, 0.005, 0.02, 0.045, 0.08, 0.125, 0.18, 0.245, 0.32, 0.405]
#Gp.print_params
#pool = Gp::Pool.new(MyFunction.new())
#generations.times do
#  pool.each do |indv|
#    sum = 0.0
#    fitness_cases_table.size.times do |i|
#      pool.deffunc.x = fitness_cases_table[i]
#      result = indv.eval
#      sum += (fitness_cases_table_out[i] - result).abs
#    end
#    indv.fitness = sum
#  end
#  pool.operate
#end
