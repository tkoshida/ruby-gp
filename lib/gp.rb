# Params
# * max_depth_for_new_trees: 個体の生成最大深さ
# * max_depth_after_crossover: 交叉後の最大深さ、これを超える場合交叉しない
# * population: 集団内の個体の数(2~)
# * generation_gap: 世代間のギャップ(0.0~1.0)
# * select_type: 選択方式(TOURNAMENT, ROULETTE)
# * tournament_k: トーナメント抽出個体数(2~)
# * crossover_fraction: 交叉確率(0.0~1.0)
# * mutant_fraction: 突然変異確率(0.0~1.0)
# * crossover_type: 交叉方法(SWAP/ONEPOINT)
# * mutant_fraction: 突然変異方法(GENERATE/LABEL)
# * depth_dependent_crossover: 深さ依存交叉(true/false)
# * parsimony_factor: 倹約度(0.0~)
# * use_adf: ADF機能使用ON/OFF(true/false)
# * adf_num: ADF集団の数(1~)
# * adf_arity: ADF関数の引数(1~)
require 'gp/gpsystem'
require 'gp/pool'
require 'gp/individual'
require 'gp/base'
require 'gp/util'

#$:.unshift(File.dirname(__FILE__)) unless
#  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Gp
  class ParameterError < StandardError; end
  class DefineFunctionError < StandardError; end

  Params = {}
  Params[:max_depth_for_new_trees] = 6
  Params[:max_depth_after_crossover] = 17
  Params[:population] = 20
  Params[:generation_gap] = 0.9
  Params[:tournament_k] = 6
  Params[:select_type] = 'TOURNAMENT'
  Params[:crossover_fraction] = 0.8
  Params[:mutant_fraction] = 0.1
  Params[:crossover_type] = 'SWAP'
  Params[:mutant_type] = 'GENERATE'
  Params[:depth_dependent_crossover] = false
  Params[:parsimony_factor] = 0.0000
  Params[:use_adf] = false
  Params[:adf_num] = 1
  Params[:adf_arity] = 2

  class << self
    def set_params(p)
      raise ArgumentError unless p
      p.each do |k, v|
        raise ParameterError, "Unknown key: #{k}" unless Params.has_key?(k)
      end
      Params.each do |k, v|
        next if p[k].nil?
        case k
        when :init_depth, :init_size
          raise ParameterError unless p[k].to_i > 0
          Params[k] = p[k].to_i
        when :population, :tournament_k,
             :max_depth_for_new_trees, :max_depth_after_crossover
          raise ParameterError unless p[k].to_i > 1
          Params[k] = p[k].to_i
        when :crossover_fraction, :mutant_fraction, :generation_gap,
             :parsimony_factor
          raise ParameterError unless (0...1.0) === p[k].to_f
          Params[k] = p[k].to_f
        when :select_type
          unless p[k] == 'TOURNAMENT' || p[k] == 'ROULETTE'
            raise ParameterError
          end
          Params[k] = p[k]
        when :crossover_type
          unless p[k] == 'SWAP' || p[k] == 'ONEPOINT'
            raise ParameterError
          end
          Params[k] = p[k]
        when :mutant_type
          unless p[k] == 'GENERATE' || p[k] == 'LABEL'
            raise ParameterError
          end
          Params[k] = p[k]
        when :depth_dependent_crossover,
             :use_adf
          unless p[k].class == TrueClass || p[k].class == FalseClass
            raise ParameterError
          end
          Params[k] = p[k]
        when :adf_num, :adf_arity
          if p[:use_adf]
            raise ParameterError unless p[k].to_i > 0
          end
          Params[k] = p[k].to_i
        else
          Params[k] = p[k]
        end
      end
    end

    def print_params
      STDOUT.puts "--------- Gp::Params -----------"
      Params.each { |k, v| puts "#{k}: #{v}" }
    end
  end
end
