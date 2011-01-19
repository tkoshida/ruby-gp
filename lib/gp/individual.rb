require 'gp/functable'
require 'gp/chrom'

module Gp
  class Individual
    attr_accessor :age
    attr_reader :fitness, :adjusted_fitness, :chrom, :adf_chroms
   
    def initialize(ft, gen_tree = true)
      raise DefineFunctionError unless ft.kind_of? FuncTable
      @age = 0
      @result, @fitness, @adjusted_fitness = 0, nil, nil
      @adf_chroms = []
      @ft = ft

      @chrom = Chrom.new(@ft, gen_tree, false)
      if Params[:use_adf]
        Params[:adf_num].times do |i|
          @adf_chroms[i] = Chrom.new(@ft, gen_tree, true)
        end
        @chrom.append_adf_chroms(@adf_chroms)
      end
    end

    def eval
      @result = @chrom.eval
    end

    def fitness=(val)
      @fitness = val
      @adjusted_fitness = 1.0 / (1.0 + @fitness)
      @adjusted_fitness -= Params[:parsimony_factor] * total_size
      @adjusted_fitness = 0.0 if @adjusted_fitness.infinite? ||
                                  @adjusted_fitness.nan?
    end

    def crossover(parent1, px1, parent2, px2, type)
      result = @chrom.crossover(parent1.chrom, px1[0],
                                parent2.chrom, px2[0], type)
      if Params[:use_adf] && @adf_chroms
        Params[:adf_num].times do |i|
          ret = @adf_chroms[i].crossover(
                                    parent1.adf_chroms[i], px1[i+1],
                                    parent2.adf_chroms[i], px2[i+1], type)
          result = false if ret == false
        end
      end
      return false if result == false
      return true
    end

    def mutate(type)
      @chrom.mutate(type)
      init_stat
    end

    def status
      stat = {}
      stat[:fitness] = @fitness
      stat[:adjusted_fitness] = @adjusted_fitness
      stat[:result] = @result
      stat[:age] = @age
      stat[:depth] = @chrom.depth
      stat[:size] = @chrom.size
      stat[:total_size] = total_size
      return stat
    end

    def size() @chrom.size end
    def depth() @chrom.depth end

    # 交叉点を取得
    def get_crosspoint(other, type)
      c1, c2 = [], []
      b1, b2 = @chrom.get_crosspoint(other.chrom, type)
      c1 << b1; c2 << b2
      if @chrom.adf_chroms
        @chrom.adf_chroms.each_with_index do |ac, i|
          b1, b2 = ac.get_crosspoint(other.chrom.adf_chroms[i], type)
          c1 << b1; c2 << b2
        end
      end
      return [c1, c2]
    end

    def total_size
      total = @chrom.size
      @adf_chroms.each { |c| total += c.size } if @adf_chroms
      return total
    end

    def to_dot
      dot = ""
      body = @chrom.to_dot("body")
      if Params[:use_adf]
        body_top = body.split(/[\(\)\s]+/).first
        dot << "PROG -> BODY;"
        dot << "BODY -> #{body_top};"
        dot << body
        Params[:adf_num].times do |i|
          body = @chrom.adf_chroms[i].to_dot("adf#{i}")
          body_top = body.split(/[\(\)\s]+/).first
          dot << "PROG -> ADFFUN#{i};"
          dot << "ADFFUN#{i} -> #{body_top};"
          dot << body
        end
      else
        dot << body
      end
      return dot
    end

    def to_sexp
      exp = ""
      exp << "BODY:\n  " if Params[:use_adf]
      exp << @chrom.to_sexp
      if Params[:use_adf]
        Params[:adf_num].times do |i|
          exp << "\nADFFUN#{i}:\n  "
          exp << @chrom.adf_chroms[i].to_sexp
        end
      end
      return exp
    end

    def sexp=(exp)
      @age = 0
      init_stat

      exparr = exp.split(/[\(\)\s]+/)
      exparr.shift if exparr.first =~ /^BODY/
      exp_body = []
      while exparr.size > 0
        break if exparr.first =~ /^ADFFUN\d+:/
        exp_body << exparr.shift
      end
      @chrom.sexp = exp_body.join(" ")
      if Params[:use_adf]
        Params[:adf_num].times do |i|
          exparr.shift
          exp_body = []
          while exparr.size > 0
            break if exparr.first =~ /^ADFFUN\d+:/
            exp_body << exparr.shift
          end
          @chrom.adf_chroms[i].sexp = exp_body.join(" ")
        end
      end
    end
 
    #######
    private
    #######

    def init_stat
      @result, @fitness, @adjusted_fitness = 0, nil, nil
    end
  end
end
