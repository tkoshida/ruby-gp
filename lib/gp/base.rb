module Gp
  class Base
    @@hidden_methods = []
    @@macro_list = {}
    @@label_list = {}

    class << self
      def hide_methods(*names)
        @@hidden_methods << names.map { |v| v.to_sym }
        @@hidden_methods.flatten!.uniq!
      end

      def set_macro(function)
        @@macro_list[function] = true
      end

      def set_label(function, label)
        @@label_list[function] = label
      end
    end

    def functions
      # Ruby 1.8 以前では methods は String のため Symbol に変換
      methods = (self.methods.map { |m| m.to_sym } - 
                 Base.new.methods.map { |m| m.to_sym } - 
                 @@hidden_methods)
      functions = methods.collect { |m|
        { :function => m, :arity => self.method(m).arity, 
          :macro => @@macro_list[m], :label => @@label_list[m] }
      }
      return functions
    end

    def initialize
    end

    def eval_training_case(indv, options)
      raise NotImplementedError, "You should overwrite this method and return fitness value after inheriting Gp::Base class"
    end

    def eval_test_case(indv, options)
      raise NotImplementedError, "You should overwrite this method and return fitness value after inheriting Gp::Base class"
    end

    def terminal_early?(info) false end
  end
end
