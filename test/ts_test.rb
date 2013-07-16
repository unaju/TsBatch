#!ruby -Ku

require 'test/unit'

require "pathname"
$:.unshift (Pathname(__FILE__).dirname + '..').expand_path.to_s
require "lib/ts"

class Ts_Tester < Test::Unit::TestCase
  def setup
  end
  
  def test_serviceid
    p TSFile.service_id "E:/conv/01-1.ts"
  end
end
