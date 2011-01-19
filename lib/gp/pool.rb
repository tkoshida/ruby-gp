# 
# pool
#
# fitnessは0に近いほど適応度が高いものとする
# ただし負の値は設定しないこと
#
require 'gp/individual'
#require 'profile'

module Gp
  class Pool
    attr_reader :pool, :generation, :deffunc, :best_indv
    def initialize(deffunc)
      raise DefineFunctionError unless deffunc.kind_of? Base
      @deffunc = deffunc
      @ft = FuncTable.new(@deffunc)
      @generation = 0
      @best_indv = nil
      @ncross, @nmutation = 0, 0
      @test_case_info = {}
      generate(@pool = [])
    end

    def eval_training_case(options = {})
      @best_indv = nil
      @pool.each_with_index do |indv, i|
        indv.fitness = @deffunc.eval_training_case(indv, options)
        if @best_indv.nil? || indv.fitness < @best_indv.fitness
          @best_indv = indv
        end
      end
      print_best_individual
    end

    def eval_test_case(options = {})
      fitness = @deffunc.eval_test_case(@best_indv, options)
      print_test_result(fitness)
      if @test_case_info[:fitness].nil? ||
          fitness < @test_case_info[:fitness]
        @test_case_info[:fitness] = fitness
        @test_case_info[:sexp] = @best_indv.to_sexp
        @test_case_info[:generation] = @generation
      end
    end

    def terminal_early?
      @deffunc.terminal_early?(info)
    end

    def each
      @pool.each { |indv| yield(indv) }
    end

    def each_with_index
      @pool.each_with_index { |indv, i| yield(indv, i) }
    end

    def [](n) @pool[n] end
    def size() @pool.size end
    alias population size

    def operate
      @best_indv = nil
      @nmutation = 0
      @ncross = 0
      sort_pool
      opsize = (@pool.size - elite_num)
      new_children = []
      (opsize / 2).times do |i|
        if flip_cross
          ret = crossover
          new_children << ret if ret
        end
      end
      @pool.each { |indv| indv.age += 1 }
      replace(new_children.flatten)
      opsize.times { |i| mutate(i) if flip_mutate }
      @generation += 1
      print_operation_result
      return [@ncross, @nmutation]
    end

    def info
      max_size, min_size, avg_size = 0, nil, 0
      max_fitness, min_fitness, avg_fitness = 0.0, nil, 0.0
      sum_size, sum_fitness = 0, 0.0
      best_index = nil
      @pool.each_with_index do |indv, i|
        max_size = indv.total_size if indv.total_size > max_size
        min_size = indv.total_size if min_size.nil? || indv.total_size < min_size
        sum_size += indv.total_size
        if indv.fitness
          if indv.fitness > max_fitness
            max_fitness = indv.fitness 
          end
          if min_fitness.nil? || indv.fitness < min_fitness
            min_fitness = indv.fitness 
            best_index = i
          end
          sum_fitness += indv.fitness
        end
      end
      info = {}
      info[:max_fitness] = max_fitness
      info[:min_fitness] = min_fitness
      info[:avg_fitness] = sum_fitness / @pool.size
      info[:max_size] = max_size
      info[:min_size] = min_size
      info[:avg_size] = sum_size / @pool.size
      info[:population] = @pool.size
      info[:generation] = @generation
      info[:best_index] = best_index
      info[:ncross] = @ncross
      info[:nmutation] = @nmutation
      info[:best_validation_fitness] = @test_case_info[:fitness]
      info[:best_validation_sexp] = @test_case_info[:sexp]
      info[:best_validation_generation] = @test_case_info[:generation]
      return info
    end

    def print_completion_message
      tci = @test_case_info
      STDOUT.print <<-END_OF_STRING
--------------------------------
Best tree found on gen #{tci[:generation]}, VALIDATION fitness = #{tci[:fitness]}
      END_OF_STRING
      STDOUT.puts tci[:sexp]
    end

    #######
    private
    #######
    def mutate(i)
      type = Params[:mutant_type]
      @pool[i].mutate(type)
      @nmutation += 1
    end

    def crossover
      type = Params[:crossover_type]
      new_indv = []
      idx1, idx2 = select_parents
      parent1 = @pool[idx1]
      parent2 = @pool[idx2]
      px1, px2 = parent1.get_crosspoint(parent2, type)
      child1 = Individual.new(@ft, false)
      child2 = Individual.new(@ft, false)
      if child1.crossover(parent1, px1, parent2, px2, type)
        if child2.crossover(parent2, px2, parent1, px1, type)
          new_indv << child1 << child2
          @ncross += 1
        end
      end
      return new_indv
    end

    def elite_num
      (@pool.size * (1.0 - Params[:generation_gap])).to_i
    end

    # n 個の個体を生成し、それぞれでツリーを形成
    def generate(target)
      size = Params[:population]
      size.times { |i| target[i] = Individual.new(@ft) }
    end

    # 交叉対象の親を選択
    def select_parents
      indices = []
      case Params[:select_type]
      when 'TOURNAMENT'
        ntry = 0
        until indices.size == 2
          cand = []
          dmy = Array.new(@pool.size) { |i| i }
          Params[:tournament_k].times do
            ret = rand(dmy.size)
            cand << dmy[ret] if @pool[dmy[ret]].adjusted_fitness
            dmy.delete_at(ret)
          end
          indices << cand.sort do |e1, e2|
            @pool[e1].adjusted_fitness <=> @pool[e2].adjusted_fitness
          end.last
          ntry += 1
          raise "Couldn't find parents" if ntry > 10
        end
      when 'ROULETTE'
        until indices.size == 2
          sum = 0.0
          @pool.each { |indv| sum += indv.adjusted_fitness }
          wheel = sum * rand()
          tmp = nil
          @pool.each_with_index do |indv, i|
            if (wheel -= indv.adjusted_fitness) <= 0
              tmp = i; break
            end
          end
          tmp = @pool.size - 1 unless tmp
          indices << tmp
        end
      end
      return indices
    end

    def replace(new_indv)
      new_indv.size.times { @pool.shift }
      new_indv.each { |child| @pool.unshift child }
    end

    def sort_pool
      @pool.sort! do |a, b|
        a.adjusted_fitness <=> b.adjusted_fitness
      end
    end

    def print_operation_result
      info = info()
      STDOUT.print <<-END_OF_STRING
Operation result:
  Size: Max = #{info[:max_size]}, Min = #{info[:min_size]}, Avg = #{info[:avg_size]}
  N cross = #{info[:ncross]},  N mutation = #{info[:nmutation]}
      END_OF_STRING
    end

    def print_best_individual
      STDOUT.print <<-END_OF_STRING
--------------------------------
Generation  = #{info[:generation]},   Avg fitness = #{info[:avg_fitness]}
Best indv: fitness = #{@best_indv.fitness}, age = #{@best_indv.age}, size = #{@best_indv.size}, depth = #{@best_indv.depth}
Best indv tree:
      END_OF_STRING
      STDOUT.puts @best_indv.to_sexp
    end

    def print_test_result(best_validation)
      STDOUT.puts "Best validation fitness: #{best_validation}"
    end

    def flip_cross
      rand < Params[:crossover_fraction] ? true : false
    end

    def flip_mutate
      rand < Params[:mutant_fraction] ? true : false
    end
  end
end
