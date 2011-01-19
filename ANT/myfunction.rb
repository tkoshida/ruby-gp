require 'gp'
require 'ant'
require 'world'

class MyFunction < Gp::Base
  # Arity: 3
  def prog3(arg0, arg1, arg2)
    arg0 + arg1 + arg2
  end

  # Arity: 2
  def prog2(arg0, arg1)
    arg0 + arg1
  end

  def if_food_ahead(indv, arg0, arg1)
    if @ant.is_food_ahead?
      indv.eval_subtree(arg0)
    else
      indv.eval_subtree(arg1)
    end
  end
  set_macro :if_food_ahead

  # Terminals
  def move_forward() @ant.move_forward end
  def turn_left() @ant.turn_left end
  def turn_right() @ant.turn_right end

  def initialize()
    @ant = nil
  end

  def eval_training_case(indv, options)
    @ant = Ant.new(World.new, 400)
    sum = 0.0
    while @ant.energy != 0
      indv.eval
    end
    return @ant.score
  end

  def eval_test_case(indv, options)
    ret = eval_training_case(indv, options)
    @ant.show_world
    return ret
  end

  def terminal_early?(info)
    return true if info[:min_fitness] == 0
    return false
  end
end
