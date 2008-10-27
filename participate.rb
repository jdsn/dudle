olddir = File.expand_path(".")
Dir.chdir("..")
require "poll"
require "datepoll"
Dir.chdir(olddir)

if $cgi.include?("revision")
	REVISION=$cgi["revision"].to_i
	table = YAML::load(`export LC_ALL=de_DE.UTF-8; bzr cat -r #{REVISION} data.yaml`)
else
	table = YAML::load_file("data.yaml")
end

puts <<HEAD
<head>
<meta http-equiv="Content-Type" content="#{CONTENTTYPE}" /> 
<meta http-equiv="Content-Style-Type" content="text/css" />
<title>dudle - #{table.name}</title>
<link rel="stylesheet" type="text/css" href="../dudle.css" title="default"/>
<link rel="stylesheet" type="text/css" href="../print.css" title="print" media="print" />
<link rel="stylesheet" type="text/css" href="../print.css" title="print" />
<link rel="alternate"  type="application/atom+xml" href="atom.cgi" />
</head>
<body>
<div id='backlink'>
<a href='..' style='text-decoration:none'>#{BACK}</a>
</div>
<h1>#{table.name}</h1>
HEAD

if $cgi.include?("add_participant")
	agreed = {}
	$cgi.params.each{|k,v|
		if k =~ /^add_participant_checked_/
			agreed[k.gsub(/^add_participant_checked_/,"")] = v[0]
		end
	}

	table.add_participant($cgi["add_participant"],agreed)
end

table.invite_delete($cgi["invite_delete"])	if $cgi.include?("invite_delete")

if $cgi.include?("add_remove_column")
	puts "Could not add/remove column #{$cgi["add_remove_column"]}" unless table.add_remove_column($cgi["add_remove_column"],$cgi["columndescription"])
end

table.add_comment($cgi["commentname"],$cgi["comment"]) if $cgi.include?("comment")
table.delete_comment($cgi["delete_comment"].to_i) if $cgi.include?("delete_comment")

puts table.to_html

puts "<div id='hint'>"
puts "<fieldset><legend>Hint</legend>"
puts "To change a line, add a new person with the same name!"
puts "</fieldset>"
puts "</div>"

MAXREV=`bzr revno`.to_i
REVISION=MAXREV unless defined?(REVISION)
log = `export LC_ALL=de_DE.UTF-8; bzr log --forward`.split("-"*60)
log.collect!{|s| s.scan(/\nrevno:.*\ncommitter.*\n.*\ntimestamp: (.*)\nmessage:\n  (.*)/).flatten}
log.shift
log.collect!{|t,c| [DateTime.parse(t),c]}
puts "<div id='history'>"
puts "<fieldset><legend>browse history</legend>"
puts "<table>"
puts "<tr>"
puts "<th>rev</th>"
puts "<th>time</th>"
puts "<th>description of change</th>"
puts "</tr>"

((REVISION-2)..(REVISION+2)).each do |i|
	if i >0 && i<=MAXREV
		if REVISION == i
			puts "<tr id='displayed_revision'><td>#{i}"
		else
			puts "<tr><td>"
			puts "<a href='?revision=#{i}' />#{i}</a>"
		end
		puts "</td>"
		puts "<td>#{log[i-1][0].strftime('%d.%m, %H:%M')}</td>"
		puts "<td>#{log[i-1][1]}</td>"
		puts "</tr>"
	end
end
puts "</table>"
puts "</fieldset>"
puts "</div>"

puts "<div id='invite_delete'>"
puts "<fieldset><legend>invite/delete participant</legend>"
puts "<form method='post' action='.'>\n"
puts "<div>"
puts "<input size='16' value='#{$cgi["invite_delete"]}' type='text' name='invite_delete' />"
puts "<input type='submit' value='invite/delete' />"
puts "</div>"
puts "</form>"
puts "</fieldset>"
puts "</div>"

puts table.add_remove_column_htmlform

puts "<div id='add_comment'>"
puts "<fieldset><legend>Comment</legend>"
puts "<form method='post' action='.'>\n"
puts "<div>"
puts "<label for='Commentname'>Name: </label><input id='Commentname' value='anonymous' type='text' name='commentname' /><br />"
puts "<textarea cols='50' rows='10' name='comment' ></textarea><br />"
puts "<input type='submit' value='Submit' />"
puts "</div>"
puts "</form>"
puts "</fieldset>"
puts "</div>"

