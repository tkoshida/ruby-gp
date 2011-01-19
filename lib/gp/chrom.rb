module Gp
  class Chrom
    class ArityStack
      attr_reader :depth, :max_depth, :stack_count

      def initialize
        @stack = []
        @stack_count = 0
        @depth = 0
        @max_depth = 0
      end

      # set arity - 1
      def a_m1=(a_m1)
        @stack_count += a_m1
        @stack << (@stack.pop - 1) if @stack.size > 0
        @stack << (a_m1 + 1)
        @depth = @stack.size
        @max_depth = @depth if @max_depth < @depth
        @stack.pop while @stack.size > 0 && @stack.last <= 0
      end

      def next_depth
        @stack.size + 1
      end
    end
  end

  class Chrom
    attr_reader :depth, :tree, :adf_chroms
    def initialize(ft, gen_tree = true, adf = false)
      @ft = ft
      @depth = 0
      @tree = []
      @current_index = -1
      @adf = adf
      @adf_chroms = nil
      @depth = generate_tree(@tree) if gen_tree
    end

    def size
      @tree.size
    end

    def eval
      @current_index = -1
      return eval_next_arg
    end

    def crossover(chrom1, x1, chrom2, x2, type)
      return false unless x1 && x2
      @tree = []
      case type
      when 'ONEPOINT'
        tree1 = chrom1.div1(x1)
        tree2 = chrom2.div2(x2)
        integrate_tree(tree1, tree2)
      when 'SWAP'
        (@tree << chrom1.tree).flatten!
        discard(@tree, x1)
        @tree.insert(x1, chrom2.subtree(x2)).flatten!
      end
      @depth = get_depth
      return false if @depth > Params[:max_depth_after_crossover]
      return true
    end

    def mutate(type)
      locus = rand(@tree.size)
      case type
      when 'GENERATE'
        discard(@tree, locus)
        generate_tree(new_tree = [])
        @tree.insert(locus, new_tree).flatten!
      when 'LABEL'
        new_token = @ft.get_token_by_arity(@tree[locus].arity, @adf)
        @tree[locus] = new_token
      end
      @depth = get_depth
    end

    def subtree(locus)
      new_tree = []
      as = ArityStack.new
      begin 
        new_tree << @tree[locus]
        as.a_m1 = @tree[locus].a_m1
        locus += 1
      end until as.stack_count == -1
      return new_tree
    end

    def append_adf_chroms(chroms)
      @adf_chroms = chroms
    end

    def locus_by_sc(sc)
      locus = nil
      loci = loci_by_sc(sc)
      locus = loci[rand(loci.size)] unless loci.nil?
      return locus
    end

    def locus_by_random
      rand(@tree.size) 
    end

    def locus_by_depth_dependent
      loci = loci_by_depth(@tree, weighted_depth(@depth))
      locus = loci[rand(loci.size)]
      return locus
    end

    # @tree の要素を先頭から locus -1 までの範囲を返す
    def div1(locus)
      @tree[0..locus-1]
    end

    # @tree の要素を locus から最後尾までの範囲を返す
    def div2(locus)
      @tree[locus..@tree.size-1]
    end

    # 交叉点を取得
    def get_crosspoint(other, type)
      my_locus = nil
      others_locus = nil
      sc = 0
      begin
        if Params[:depth_dependent_crossover]
          my_locus = locus_by_depth_dependent
        else
          my_locus = locus_by_random
        end
        case type
        when 'ONEPOINT'
          unless @tree.size > 1 && other.tree.size > 1
            return [nil, nil]
          end
          if my_locus > 0
            # 一つ手前のノードが同じStackCountのノードを探す
            sc = sc_by_locus(my_locus - 1) # sc >= 0
            locus = other.locus_by_sc(sc)
            others_locus = locus + 1 if locus
          end
        when 'SWAP'
          if Params[:depth_dependent_crossover]
            others_locus = other.locus_by_depth_dependent
          else
            others_locus = other.locus_by_random
          end
        end
      end while others_locus.nil?
      return [my_locus, others_locus]
    end

    def eval_subtree(index)
      @current_index = index - 1
      return eval_next_arg
    end

    def to_dot(id)
      @current_index = 0
      to_dot_recursively(s = [], set = String.new, list = String.new, id)
      raise RuntimeError unless s.size == 1
      return set + list
    end

    def to_sexp
      @current_index = 0
      to_sexp_recursively(exp = "")
      return exp
    end

    def sexp=(exp)
      @tree = [] # ツリーを作成しなおし
      exparr = exp.split(/[\(\)\s]+/)
      exparr.reject! { |x| x == "" }
      generate_by_sexp(exparr, 1)
      @depth = get_depth
    end

    #######
    private
    #######

    def integrate_tree(tree1, tree2)
      work_tree = tree1 + tree2
      tmp_tree = []
      locus = tmp_tree.size
      as = ArityStack.new
      begin
        if as.next_depth == Params[:max_depth_after_crossover]
          # 最大深さに達する場合は終端ノードとする
          if work_tree[0].terminal?
            tmp_tree[locus] = work_tree.shift
          else
            discard(work_tree, 0) # 部分木は切り落とす
            get_terminal(tmp_tree, locus)
          end
        else
          tmp_tree[locus] = work_tree.shift
        end
        as.a_m1 = tmp_tree[locus].a_m1
        locus += 1
      end until work_tree.size == 0
      @tree = tmp_tree
    end

    def sc_by_locus(locus, tree = @tree)
      as = ArityStack.new
      tree.size.times do |i|
        as.a_m1 = tree[i].a_m1
        break if i == locus
      end
      return as.stack_count
    end

    def sc_of_tree(tree = @tree)
      as = ArityStack.new
      tree.size.times { |i| as.a_m1 = tree[i].a_m1 }
      return as.stack_count
    end

    def loci_by_depth(array, depth)
      loci = []
      as = ArityStack.new
      array.size.times do |i| 
        as.a_m1 = array[i].a_m1
        loci << i if depth == as.depth
      end
      return loci
    end

    def loci_by_sc(sc)
      as = ArityStack.new
      same_sc_loci = []
      @tree.size.times do |i|
        as.a_m1 = @tree[i].a_m1
        same_sc_loci << i if as.stack_count == sc
      end
      return nil unless same_sc_loci.size > 0
      return same_sc_loci
    end

    def weighted_depth(max_depth)
      depth = 2
      wheel = rand
      while depth < @depth
        break if (wheel -= (1.0 / (2 ** (depth - 1)))) < 0
        depth += 1
      end
      depth = max_depth if depth > max_depth
      return depth
    end

    def discard(array, locus)
      as = ArityStack.new
      begin 
        as.a_m1 = array[locus].a_m1
        array.delete_at(locus)
      end until as.stack_count == -1
    end

    def get_terminal(array, index)
      array[index] = @ft.get_random_terminal(@adf)
      return array[index].a_m1
    end

    def get_function(array, index)
      array[index] = @ft.get_random_function(@adf)
      return array[index].a_m1
    end

    def get_token(array, index)
      array[index] = @ft.get_random_token(@adf)
      return array[index].a_m1
    end
 
    def current_token
      @tree[@current_index]
    end

    def get_depth(array = @tree)
      as = ArityStack.new
      array.size.times { |i| as.a_m1 = array[i].a_m1 }
      raise RuntimeError, "StackCount Error" unless as.stack_count == -1
      return as.max_depth
    end

    # ツリーの生成
    #   target にツリーを生成する
    #   生成したツリーの深さを返す
    def generate_tree(target)
      locus = target.size
      as = ArityStack.new
      begin
        if as.next_depth == Params[:max_depth_for_new_trees]
          # 最大深さに達する場合は終端ノードとする
          get_terminal(target, locus)
        elsif as.next_depth < 1
          get_function(target, locus)
        else
          get_token(target, locus)
        end
        as.a_m1 = target[locus].a_m1
        locus += 1
      end until as.stack_count == -1
      get_depth(target)
    end

    def eval_next_arg
      @current_index += 1
      token = current_token
      ret = nil
      if token.macro
        indices = []
        tmp_index = @current_index + 1
        token.arity.times do
          indices << tmp_index
          as = ArityStack.new
          begin
            as.a_m1 = @tree[tmp_index].a_m1
            tmp_index += 1
          end until as.stack_count == -1
        end
        args = [] << self << indices
        args.flatten!
        ret = token.invoke(args)
        @current_index = tmp_index - 1
      else
        args = []
        token.arity.times { args << eval_next_arg }
        ret = token.invoke(args)
        if @adf_chroms && token.kind_of?(TokenAdfFunction)
          ret =  @adf_chroms[$1.to_i].eval
        end
      end
      return ret
    end

    def skip_next_arg
      as = ArityStack.new
      begin
        as.a_m1 = current_token.a_m1
        @current_index += 1
      end until as.stack_count == -1
    end

    def to_dot_recursively(s, set, list, id)
      elem = "#{current_token.function}_#{@current_index}_#{id}"
      set << elem + " [label = \"#{current_token.label}\"];\n"
      current_token.arity.times do
        @current_index += 1
        to_dot_recursively(s, set, list, id)
        list << elem + " -> " + s.pop + ";\n"
      end
      s.push elem
    end

    def to_sexp_recursively(exp)
      arity = current_token.arity
      bracket = false
      if arity > 0
        exp << "("
        bracket = true
      end
      exp << "#{current_token.label} "
      arity.times do
        @current_index += 1
        to_sexp_recursively(exp)
      end
      if bracket
        exp.sub!(/ +$/, '')
        exp << ") "
      end
    end

    def generate_by_sexp(exparr, depth)
      elem = exparr.shift
      token = @ft.gen_token_by_name(elem)
      @tree << token
      token.arity.times do
        generate_by_sexp(exparr, depth + 1)
      end
    end
  end
end
