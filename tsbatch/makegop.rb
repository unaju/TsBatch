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



def main
  # 対象directory取得
  dir = get_input("ts directory")
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

