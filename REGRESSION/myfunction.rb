require 'gp'

class MyFunction < Gp::Base
  attr_writer :x
  hide_methods :x=
  set_label :add, "+"
  set_label :sub, "-"
  set_label :mul, "*"
  set_label :div, "%"

  # Arity: 4
  #def iflte(val1, val2, val3, val4) (val1 < val2) ? val3 : val4 end

  # Arity: 2
  def add(val1, val2) val1 + val2 end
  def sub(val1, val2) val1 - val2 end
  def mul(val1, val2) val1 * val2 end
  def div(val1, val2) (val2 == 0) ? 1.0 : (val1 / val2) end

  # Arity: 1
  #def sin(var) Math.sin(var) end
  #def cos(var) Math.cos(var) end
  #def exp(var) return var if var <= 0; Math.exp(var) end
  #def sqrt(var) return var if var <= 0; Math.sqrt(var) end
  #def log(var) return var if var <= 0; Math.log(var) end
  #def log10(var) return var if var <= 0; Math.log10(var) end

  # Terminals
  #def R() rand end
  def x() @x end
  def CONSTANT_GENERATOR()
    rand() * 10 - 5.0
  end

  def initialize()
    @x = 0
    @fitness_cases_table = 
      [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
    @fitness_cases_table_out = 
      [0.0, 0.005, 0.02, 0.045, 0.08, 0.125, 0.18, 0.245, 0.32, 0.405]
  end

  def eval_training_case(indv, options)
    sum = 0.0
    @fitness_cases_table.size.times do |i|
      @x = @fitness_cases_table[i]
      result = indv.eval
      sum += (@fitness_cases_table_out[i] - result).abs
    end
    return sum
  end

  def eval_test_case(indv, options)
    eval_training_case(indv, options)
  end
end
