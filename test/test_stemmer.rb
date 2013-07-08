require 'test/unit'
require 'nlp_arabic'

class StemmerTest < Test::Unit::TestCase
  def test_english_hello
    assert_equal "hello world", "hello world"
  end

end
