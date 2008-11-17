################################
# Author:  Benjamin Kellermann #
# Licence: CC-by-sa 3.0        #
#          see Licence         #
################################

require "hash"
require "yaml"

class Poll
	attr_reader :head, :name, :hidden
	def initialize name,hidden
		@name = name
		@hidden = hidden
		@head = {}
		@data = {}
		@comment = []
		store "Poll #{name} created"
	end
	def sort_data fields
		if fields.include?("name")
			until fields.pop == "name"
			end
			@data.sort{|x,y|
				cmp = x[1].compare_by_values(y[1],fields) 
				cmp == 0 ? x[0] <=> y[0] : cmp
			}
		else
			@data.sort{|x,y| x[1].compare_by_values(y[1],fields) }
		end
	end
	def head_to_html
		ret = "<tr><th><a href='?sort=name'>Name</a></th>\n"
		@head.sort.each{|columntitle,columndescription|
			ret += "<th title='#{columndescription}'><a href='?sort=#{columntitle}'>#{columntitle}</a></th>\n"
		}
		ret += "<th><a href='.'>Last Edit</a></th>\n"
		ret += "</tr>\n"
		ret
	end
	def to_html
		ret = "<div id='polltable'>\n"
		ret += "<form method='post' action='.'>\n"
		ret += "<table border='1'>\n"

		ret += head_to_html
		sort_data($cgi.include?("sort") ? $cgi.params["sort"] : ["timestamp"]).each{|participant,poll|
			ret += "<tr>\n"
			ret += "<td class='name'>#{participant}</td>\n"
			@head.sort.each{|columntitle,columndescription|
				klasse = poll[columntitle]
				case klasse 
				when nil
					value = UNKNOWN
					klasse = "undecided"
				when "0 yes"
					value = YES
				when "2 no"
					value = NO
				when "1 maybe"
					value = MAYBE
				end
				ret += "<td class='#{klasse}' title='#{participant}: #{columntitle}'>#{value}</td>\n"
			}
			ret += "<td class='date'>#{poll['timestamp'].strftime('%d.%m, %H:%M')}</td>"
			ret += "</tr>\n"
		}
		
		# PARTICIPATE
		ret += "<tr id='add_participant'>\n"
		ret += "<td class='name'><input size='16' type='text' name='add_participant' title='To change a line, add a new person with the same name!' /></td>\n"
		@head.sort.each{|columntitle,columndescription|
			ret += "<td class='checkboxes'>
			<table><tr>
			<td class='input-yes'>#{YES}</td>
			<td><input type='radio' value='0 yes' name='add_participant_checked_#{columntitle}' title='#{columntitle}' /></td>
			</tr><tr>
			<td class='input-no'>#{NO}</td>
			<td><input type='radio' value='2 no' name='add_participant_checked_#{columntitle}' title='#{columntitle}' checked='checked' /></td>
			</tr><tr>
			<td class='input-maybe'>#{MAYBE}</td>
			<td><input type='radio' value='1 maybe' name='add_participant_checked_#{columntitle}' title='#{columntitle}' /></td>
			</tr></table>
			</td>\n"
		}
		ret += "<td class='checkboxes'><input type='submit' value='add/edit' /></td>\n"

		ret += "</tr>\n"

		# SUMMARY
		ret += "<tr><td class='name'>total</td>\n"
		@head.sort.each{|columntitle,columndescription|
			yes = 0
			undecided = 0
			@data.each_value{|participant|
				if participant[columntitle] == "0 yes"
					yes += 1
				elsif !participant.has_key?(columntitle) or participant[columntitle] == "1 maybe"
					undecided += 1
				end
			}

			if @data.empty?
				percent_f = 0
			else
				percent_f = 100*yes/@data.size
			end
			percent = "#{percent_f}#{CGI.escapeHTML("%")}" unless @data.empty?
			if undecided > 0
				percent += "-#{(100.0*(undecided+yes)/@data.size).round}#{CGI.escapeHTML("%")}"
			end

			ret += "<td class='sum' title='#{percent}' style='"
			["","background-"].each {|c|
				ret += "#{c}color: rgb("
				3.times{ 
					ret += (c == "" ? "#{155+percent_f}" : "#{100-percent_f}")
					ret += ","
				}
				ret.chop!
				ret += ");"
			}
			ret += "'>#{yes}</td>\n"
		}

		ret += "</tr>"
		ret += "</table>\n"
		ret += "</form>\n"
		ret += "</div>"
		
		ret += "<div id='comments'>"
		unless @comment.empty?
			ret	+= "<fieldset><legend>Comments</legend>"
			@comment.each_with_index{|c,i|
				time,name,comment = c
				ret += <<COMMENT
<form method='post' action='.'>
<div>
	<fieldset>
		<legend>#{name} said on #{time.strftime("%d.%m, %H:%M")}
			<input type='hidden' name='delete_comment' value='#{i}' />
			&nbsp;
			<input class='delete_comment_button' type='submit' value='delete' />
		</legend>
		#{comment}
	</fieldset>
</div>
</form>
COMMENT
			}
			ret += "</fieldset>"
		end

		ret += "</div>\n"
		ret
	end
	def add_remove_column_htmlform
		return <<END
<div id='add_remove_column'>
<fieldset><legend>add/remove column</legend>
<form method='post' action='.'>
<div>
		<label for='columntitle'>Columntitle: </label>
		<input id='columntitle' size='16' type='text' value='#{$cgi["add_remove_column"]}' name='add_remove_column' />
		<label for='columndescription'>Description: </label>
		<input id='columndescription' size='30' type='text' value='#{$cgi["columndescription"]}' name='columndescription' />
		<input type='submit' value='add/remove column' />
</div>
</form>
</fieldset>
</div>
END
	end
	def add_participant(name, agreed)
		htmlname = CGI.escapeHTML(name.strip)
		@data[htmlname] = {"timestamp" => Time.now }
		@head.each_key{|columntitle|
			@data[htmlname][columntitle] = agreed[columntitle.to_s]
		}
		store "Participant #{name.strip} edited"
	end
	def invite_delete(name)
		htmlname = CGI.escapeHTML(name.strip)
		if @data.has_key?(htmlname)
			@data.delete(htmlname)
			store "Participant #{name.strip} deleted"
		else
			add_participant(name,{})
		end
	end
	def store comment
		File.open("data.yaml", 'w') do |out|
			out << "# This is a dudle poll file\n"
			out << self.to_yaml
			out.chmod(0660)
		end
		vcs_commit(CGI.escapeHTML(comment))
	end
	def add_comment name, comment
		@comment << [Time.now, CGI.escapeHTML(name.strip), CGI.escapeHTML(comment.strip).gsub("\r\n","<br />")]
		store "Comment added by #{name}"
	end
	def delete_comment index
		store "Comment from #{@comment.delete_at(index)[1]} deleted"
	end
	def add_remove_column name, description
		add_remove_parsed_column CGI.escapeHTML(name.strip), CGI.escapeHTML(description.strip)
	end
	def add_remove_parsed_column columntitle, description
		if @head.include?(columntitle)
			@head.delete(columntitle)
			action = "deleted"
		else
			@head[columntitle] = description
			action = "added"
		end
		store "Column #{columntitle} #{action}"
		true
	end
end

if __FILE__ == $0
require 'test/unit'
require 'cgi'
require 'pp'

SITE = "glvhc_8nuv_8fchi09bb12a-23_uvc"
class Poll
	attr_accessor :head, :data, :comment
	def store comment
	end
end

class PollTest < Test::Unit::TestCase
	def setup
		@poll = Poll.new(SITE, false)
	end
	def test_init
		assert(@poll.head.empty?)
	end
	def test_add_participant
		@poll.head["Item 2"] = ""
		@poll.add_participant("bla",{"Item 2" => true})
		assert_equal(Time, @poll.data["bla"]["timestamp"].class)
		assert(@poll.data["bla"]["Item 2"])
	end
	def test_invite_delete
		@poll.invite_delete(" bla ")
		assert_equal(Hash, @poll.data["bla"].class)
		@poll.invite_delete("   bla  ")
		assert(@poll.data.empty?)
	end
	def test_add_comment
		@poll.add_comment("blabla","commentblubb")
		assert_equal(Time, @poll.comment[0][0].class)
		assert_equal("blabla", @poll.comment[0][1])
	end
	def test_add_remove_column
		assert(@poll.add_remove_column(" bla  ", ""))
		assert(@poll.head.include?("bla"))
		assert(@poll.add_remove_column("   bla ", ""))
		assert(@poll.head.empty?)
	end
end

end
