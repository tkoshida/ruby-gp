module Gp
  class Token
    attr_reader :function, :arity, :macro, :label
    def initialize(function, arity, macro, label)
      raise ArgumentError unless function
      raise ArgumentError unless arity
      @function = function
      @arity = arity
      @macro = macro
      @label = label || function
    end
    def a_m1() @arity - 1 end
    def terminal?() @arity.zero? end
    def invoke(args) end
  end

  class TokenUserDefine < Token
    def initialize(function, arity, macro, label, deffunc)
      super(function, arity, macro, label)
      @deffunc = deffunc
    end

    def invoke(args)
      @deffunc.method(function).call(*args)
    end
  end

  class TokenConstValue < Token
    def initialize(constval)
      super(constval.to_s, 0, nil, nil)
      @constval = constval
    end

    def invoke(args)
      @constval
    end
  end

  class TokenAdfFunction < Token
    def initialize(function, arity, label, ats)
      super(function, arity, nil, label)
      @ats = ats # ADF Terminals
    end

    def invoke(args)
      @arity.times { |i| @ats[i].val = args[i] }
    end
  end

  class TokenAdfTerminal < Token
    attr_accessor :val
    def initialize(function)
      super(function, 0, nil, nil)
      @val = nil
    end

    def invoke(args)
      @val
    end
  end
end
