#!ruby -Ku
# Windows用の文字コード変換ライブラリ

#require 'nkf'
require "kconv"
require "uconv/uconv" # uconvはgemで入らないので自前ビルドが必要.

# コンソールの文字コードに変換するメソッド
PRINT_ENCODE_CONV = case Encoding.default_external
  when Encoding::UTF_8 then :to_s
  when Encoding::Windows_31J then :u8tosjis
end

# UconvのmethodがStringに定義されていない場合は入れる
unless "".methods.find {|s| s == :u8tosjis }
  class String
    Uconv.methods(false).grep(/^(u\d+|sjis|euc)to/).each {|sym|
      define_method(sym){ Uconv.__send__(sym,self) }
    }
  end
end

# コンソールの文字コードに変換
def conv_out_encode str; str.__send__ PRINT_ENCODE_CONV; end

def win_print msg; print conv_out_encode msg.to_s; end
def win_puts msg; puts conv_out_encode msg.to_s; end

# Windows上で実行. sjis.
def win_sys cmd; `#{cmd.u8tosjis}`.toutf8; end
# binaryを読み込む場合
def win_sys_pipe cmd; IO.binread("|#{cmd}".u8tosjis); end

# mp4box等はstderrに全て出力する場合があるためリダイレクトさせる
def win_rsys cmd; win_sys cmd + " 2>&1" end

