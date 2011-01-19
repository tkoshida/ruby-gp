require 'yaml'
require 'tempfile'

module Gp
  module Util

    def Util::load_yaml(path)
      str = ""
      File.open(path, "r") { |f| f.each_line { |line| str << line } }
      data = YAML::load(str)
      return data
    end

    def Util::dump_yaml(path, data)
      str = YAML::dump(data)
      File.open(path, "w") { |f| str.each { |line| f.puts line } }
    end

    def Util::serialize_file(pool, out_path)
      data = serialize(pool)
      File.open(out_path, "wb") { |f| f.write data }
    end

    def Util::serialize(pool)
      data = {}
      data[:params] = Params
      data[:pool] = pool
      return Marshal.dump(data)
    end

    def Util::load_file(path)
      data = nil
      File.open(path, "rb") { |f| data = f.read }
      return load(data)
    end

    def Util::load(data)
      md = Marshal.load(data)
      Gp::set_params(md[:params])
      return md[:pool]
    end

    # 決定木の描画
    # indvo で指定した個体の決定木を gnu dot で png 形式で、
    # out_path に出力する。
    def Util::make_dot(out_path, indv)
      tmp = Tempfile.open("gp")
      tmp.puts "digraph result {\n"
      tmp.puts "  graph[rankdir = LR];"
      #tmp.puts "  graph[size = \"4, 8\"];"
      tmp.print indv.to_dot
      tmp.puts "}"
      tmp.close
      system("dot -Tpng #{tmp.path} -o #{out_path}")
      tmp.close(true)
    end

    # GNU plot によるグラフ作成
    # y 軸は logscale とする
    def Util::make_plot(out_path, data, title, option = {})
      tmp = Tempfile.open("gp")
      data.each { |d| tmp.puts d }
      tmp.close

      gnuplot = IO.popen("gnuplot", "w")
      gnuplot << "set terminal png\n"
      gnuplot << "set output \'#{out_path}\'\n"
      gnuplot << "set logscale y\n"
      gnuplot.flush
      gnuplot << "plot \'#{tmp.path}\' title \"#{title}\" w l\n"
      gnuplot.flush
      gnuplot << "q\n"
      gnuplot.flush
      gnuplot.close

      tmp.close(true)
    end

    def Util::make_plot_with_file(out_path, files)
      gnuplot = IO.popen("gnuplot", "w")
      gnuplot << "set terminal png\n"
      gnuplot << "set output \'/dev/null'\n"
      #gnuplot << "set logscale y\n"
      gnuplot.flush
      files.size.times do |i|
        f = files[i]
        if i == 0
          gnuplot << "plot \'#{f[:plot_path]}\' " + 
                        "title \"#{f[:title]}\" #{f[:option]}\n"
        else
          # png出力の場合はこのおまじないが必要らしい
          gnuplot << "set output \'#{out_path}\'\n" if i == files.size - 1
          gnuplot << "replot \'#{f[:plot_path]}\' " + 
                        "title \"#{f[:title]}\" #{f[:option]}\n"
        end
      end
      gnuplot.flush
      gnuplot << "q\n"
      gnuplot.flush
      gnuplot.close
    end

    #def Util::flip(p) #:nodoc:
    #  return rand < p ? true : false
    #end
  end
end

