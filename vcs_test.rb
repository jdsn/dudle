if __FILE__ == $0
require "test/unit"
require "pp"
require ARGV[0]
require "benchmark"

class VCS_test < Test::Unit::TestCase
	def setup
		@data = ["foo","bar","baz","spam","ham","egg"]
		@history = ["aaa","bbb","ccc","ddd","eee","fff"]
		@repo = "/tmp/vcs_test_#{rand(10000)}"
		Dir.mkdir(@repo)
		Dir.chdir(@repo)
		VCS.init
		File.open("data.txt","w").close
		VCS.add("data.txt")
		@data.each_index{|i|
			File.open("data.txt","w"){|f| f << @data[i] }
			VCS.commit(@history[i])
		}
		@b = 0
		@t = ""
	end
	def teardown
		Dir.chdir("/")
		`rm -rf #{@repo}`
		puts "#{@t}: #{@b}"
	end
	def test_cat
		@data.each_with_index{|item,revnominusone|
			result = ""
			@b += Benchmark.measure{
				result = VCS.cat(revnominusone+1,"data.txt")
			}.total
			assert_equal(item,result,"revno: #{revnominusone+1}")
		}
		@t = "cat"
	end
	def test_revno
		r = -1
		@b += Benchmark.measure{
			r = VCS.revno
		}.total
		assert_equal(@data.size,r)
		@t = "revno"
	end
	def test_history
		l = nil
		@b += Benchmark.measure{
			l = VCS.history
		}.total
		assert_equal(@data.size,l.size)
		@history.each_with_index{|h,revminusone|
			assert_equal(h,l[revminusone+1].comment)
		}

		@t = "history"
	end
end 
end
