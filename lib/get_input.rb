#!ruby -Ku
# ディレクトリ等の入力をコマンドラインからも受け付けるようにするやつ

require 'kconv'

# rubyは引数を与えると,引数のファイルの中身をSTDINに入れてしまうため,
# ARGVがあるか無いかで処理を変更する
@@argv = ARGV.empty? ? nil : ARGV.reverse

def get_input input_type# = "Directory"
  if @@argv
    @@argv.pop.to_s # popがnilの場合は空行入力と同じ
  else
    print "#{input_type} > "
    gets.to_s.chomp.toutf8
  end
end


