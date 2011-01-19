require 'gp/token'

module Gp
  class FuncTable
    def initialize(deffunc)
      @functions = []
      @terminals = []
      @adf_functions = []
      @adf_terminals = []
      @deffunc = deffunc
      list = @deffunc.functions
      list.size.times do |i|
        token = TokenUserDefine.new(
                          list[i][:function],
                          list[i][:arity] - (list[i][:macro] ? 1 : 0),
                          list[i][:macro],
                          list[i][:label],
                          @deffunc)
        if token.arity == 0 
          @terminals.push token
        elsif token.arity > 0
          @functions.push token
        else
          raise DefineFunctionError, "Invalid function defined"
        end
      end
      unless @functions.size > 0
        raise DefineFunctionError, "No function defined"
      end
      unless @terminals.size > 0
        raise DefineFunctionError, "No terminal defined"
      end
      if Params[:use_adf]
        Params[:adf_arity].times do |i|
          @adf_terminals << TokenAdfTerminal.new("ADFV#{i}")
        end
        Params[:adf_num].times do |i|
          @adf_functions << TokenAdfFunction.new("ADFFUN#{i}",
                                                 Params[:adf_arity],
                                                 nil,
                                                 @adf_terminals)
        end
      end
    end

    def get_random_token(adf = false)
      if rand() > 0.5
        return get_random_function(adf)
      else
        return get_random_terminal(adf)
      end
    end

    def get_random_function(adf = false)
      return @functions[rand(@functions.size)] if adf
      r = rand(@functions.size + @adf_functions.size)
      if r < @functions.size
        return @functions[r]
      else
        return @adf_functions[r - @functions.size]
      end
    end

    def get_random_terminal(adf = false)
      return @adf_terminals[rand(@adf_terminals.size)] if adf
      terminal = @terminals[rand(@terminals.size)]
      if terminal.function.to_s == "CONSTANT_GENERATOR"
        cval = @deffunc.method("CONSTANT_GENERATOR").call()
        terminal = TokenConstValue.new(cval)
      end
      return terminal
    end

    def get_token_by_arity(arity, adf = false)
      token = nil
      if arity > 0
        tokens = []
        @functions.each { |t| tokens << t if t.arity == arity }
        unless adf
          @adf_functions.each { |t| tokens << t if t.arity == arity }
        end
        token = tokens[rand(tokens.size)]
      else
        token = get_random_terminal(adf)
      end
      return token
    end

    def gen_token_by_name(name)
      token = nil
      case name
      when /^ADFV(\d+)$/
        return @adf_terminals[$1.to_i]
      when /^ADFFUN(\d+)$/
        return @adf_functions[$1.to_i]
      when /^([\d\.]+)$/
        return TokenConstValue.new(name.to_f)
      else
        @functions.each do |t|
          return t if t.label.to_s == name
        end
        @terminals.each do |t|
          return t if t.label.to_s == name
        end
      end
      return token
    end
  end
end
