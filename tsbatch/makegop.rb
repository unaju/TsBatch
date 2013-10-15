#!ruby -Ku
# 
# GOPリスト生成バッチ.
# エンコード前に実行.
# 処理対象ディレクトリのgopリスト無しのtsファイルに対して再帰的に実行される.

#!ruby -Ku
require "yaml"
require "pathname"
require "kconv"

MYDIR = Pathname.new(__FILE__).dirname.expand_path
libdir = (MYDIR + "../lib").expand_path
#require(libdir + "wincode")
require(libdir + "tsfilelist")

MME = YAML.load_file((MYDIR + "config.yml").to_s)[:MME]

# rubyは引数を与えると,引数のファイルの中身をSTDINに入れてしまうため,
# ARGVがあるか無いかで処理を変更する
@@argv = ARGV.empty? ? nil : ARGV.reverse

def get_dirname
  if @@argv
    @@argv.pop.to_s # popがnilの場合は空行入力と同じ
  else
    print "dir > "
    gets.to_s.chomp.toutf8
  end
end


def main
  # 対象directory取得
  dir = get_dirname
  return if dir.empty?
  dir = wpath dir
  
  # ファイル取得
  tsf = TSFileList.make_nogop(dir)

  # 確認
  puts "files:\n" + tsf.collect{ |f| f.to_s.sub(dir.to_s, "") }.join("\n")
  print "y/n >"
  return unless STDIN.gets.to_s.chomp.downcase == "y"
  
  # 実行
  tsf.each{ |file|
  	puts "batch #{file}"
    system %Q!"#{MME}" -g -q "#{file}"! # sjisのまま扱っているためそのまま実行
  }
  
  main # 次を実行
end
main if __FILE__ == $0

