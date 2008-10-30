#!/usr/bin/env ruby
load "/home/ben/src/lib.rb/pphtml.rb"
require "pp"
require "yaml"
require "cgi"
require "poll"
require "datepoll"

$htmlout += <<HEAD
<head>
<title>dudle</title>
<link rel="alternate"  type="application/atom+xml" href="atom.cgi" />
</head>
<body>
HEAD

if $cgi.include?("create_poll")
	SITE=$cgi["create_poll"]
	unless File.exist?(SITE)
		Dir.mkdir(SITE)
		Dir.chdir(SITE)
		`bzr init`
		File.symlink("../index.cgi","index.cgi")
		File.symlink("../atom.cgi","atom.cgi")
		File.open("data.yaml","w").close
		`bzr add data.yaml`
		hidden = ($cgi["hidden"] == "true")
		case $cgi["poll_type"]
		when "Poll"
			Poll.new SITE, hidden
		when "DatePoll"
			DatePoll.new SITE, hidden
		end
		Dir.chdir("..")
		if hidden
			$htmlout += <<HIDDENINFO
<fieldset>
<legend>Info</legend>
Poll #{SITE} created successfull!
<br />
Please remember the url (<a href="#{SITE}">#{$cgi.server_name}#{$cgi.script_name.gsub(/index.cgi$/,"")}#{SITE}</a>) while it will not be visible here.
</fieldset>
HIDDENINFO
		end
	else
		$htmlout += "<fieldset><legend>Error</legend>This poll already exists!</fieldset>"
	end
end

$htmlout += "<fieldset><legend>Available Polls</legend>"
$htmlout += "<table><tr><th>Poll</th><th>Last change</th></tr>"
Dir.glob("*/data.yaml").sort_by{|f|
	File.new(f).mtime
}.reverse.collect{|f| 
	f.gsub(/\/data\.yaml$/,'')
}.each{|site|
	unless YAML::load_file("#{site}/data.yaml").hidden
		$htmlout += "<tr>"
		$htmlout += "<td class='site'><a href='#{site}'>#{site}</a></td>"
		$htmlout += "<td class='mtime'>#{File.new(site + "/data.yaml").mtime.strftime('%d.%m, %H:%M')}</td>"
		$htmlout += "</tr>"
	end
}
$htmlout += "</table>"
$htmlout += "</fieldset>"

$htmlout += <<CHARSET
<fieldset><legend>change charset</legend>
#{UTFASCII}
</fieldset>
CHARSET

$htmlout += <<CREATE
<fieldset><legend>Create new Poll</legend>
<form method='post' action='.'>
<table>
<tr>
	<td><label title="#{poll_name_tip = "the name equals the link under which you receive the poll"}" for="poll_name">Name:</label></td>
	<td><input title="#{poll_name_tip}" id="poll_name" size='16' type='text' name='create_poll' value='#{$cgi["create_poll"]}' /></td>
</tr>
<tr>
	<td><label for="poll_type">Type:</label></td>
	<td>
		<select id="poll_type" name="poll_type">
			<option value="Poll" selected="selected">normal</option>
			<option value="DatePoll">date</option>
		</select>
	</td>
</tr>
<tr>
	<td><label title="#{hidden_tip = "do not list the poll here (you have to remember the link)"}" for="hidden">Hidden?:</label></td>
	<td><input id="hidden" type="checkbox" name="hidden" value="true" title="#{hidden_tip}" /></td>
</tr>
<tr>
	<td colspan='2'><input type='submit' value='create' /></td>
</tr>
</table>
</form>
</fieldset>
CREATE

$htmlout += "</body></html>"

