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

$htmlout += <<HEAD
<head>
	<meta http-equiv="Content-Type" content="#{TYPE}"; charset="#{CHARSET}" /> 
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
	$htmlout += "Could not add/remove column #{$cgi["add_remove_column"]}" unless table.add_remove_column($cgi["add_remove_column"],$cgi["columndescription"])
end

table.add_comment($cgi["commentname"],$cgi["comment"]) if $cgi.include?("comment")
table.delete_comment($cgi["delete_comment"].to_i) if $cgi.include?("delete_comment")

$htmlout += table.to_html

MAXREV=`bzr revno`.to_i
REVISION=MAXREV unless defined?(REVISION)
log = `export LC_ALL=de_DE.UTF-8; bzr log --forward`.split("-"*60)
log.collect!{|s| s.scan(/\nrevno:.*\ncommitter.*\n.*\ntimestamp: (.*)\nmessage:\n  (.*)/).flatten}
log.shift
log.collect!{|t,c| [DateTime.parse(t),c]}
$htmlout += <<HISTORY
<div id='history'>
	<fieldset><legend>browse history</legend>
	<table>
		<tr>
			<th>rev</th>
			<th>time</th>
			<th>description of change</th>
		</tr>
HISTORY

((REVISION-2)..(REVISION+2)).each do |i|
	if i >0 && i<=MAXREV
		if REVISION == i
			$htmlout += "<tr id='displayed_revision'><td>#{i}"
		else
			$htmlout += "<tr><td>"
			$htmlout += "<a href='?revision=#{i}'>#{i}</a>"
		end
		$htmlout += "</td>"
		$htmlout += "<td>#{log[i-1][0].strftime('%d.%m, %H:%M')}</td>"
		$htmlout += "<td>#{log[i-1][1]}</td>"
		$htmlout += "</tr>"
	end
end
$htmlout += "</table>"
$htmlout += "</fieldset>"
$htmlout += "</div>"

$htmlout += <<INVITEDELETE
<div id='invite_delete'>
	<fieldset>
		<legend>invite/delete participant</legend>
		<form method='post' action='.'>
			<div>
				<input size='16' value='#{$cgi["invite_delete"]}' type='text' name='invite_delete' />
				<input type='submit' value='invite/delete' />
			</div>
		</form>
	</fieldset>
</div>
INVITEDELETE

$htmlout += table.add_remove_column_htmlform

$htmlout += <<ADDCOMMENT
<div id='add_comment'>
	<fieldset>
		<legend>Comment</legend>
		<form method='post' action='.'>
			<div>
				<label for='Commentname'>Name: </label>
				<input id='Commentname' value='anonymous' type='text' name='commentname' />
				<br />
				<textarea cols='50' rows='10' name='comment' ></textarea>
				<br />
				<input type='submit' value='Submit' />
			</div>
		</form>
	</fieldset>
</div>
ADDCOMMENT

$htmlout += "</body></html>"
