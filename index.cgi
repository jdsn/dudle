#!/usr/bin/env ruby

################################
# Author:  Benjamin Kellermann #
# License: CC-by-sa 3.0        #
#          see License         #
################################

require "yaml"
require "cgi"


if __FILE__ == $0

$cgi = CGI.new

TYPE = "text/html"
#TYPE = "application/xhtml+xml"
CHARSET = "utf-8"

$htmlout = <<HEAD
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
HEAD

load "charset.rb"
if File.exists?("config.rb")
	load "config.rb"
else
	puts "\nPlease configure me in the file config.rb"
	exit
end

require "poll"
require "datepoll"
require "timepoll"

$htmlout += <<HEAD
<head>
	<title>dudle</title>
	<meta http-equiv="Content-Type" content="#{TYPE}; charset=#{CHARSET}" /> 
	<meta http-equiv="Content-Style-Type" content="text/css" />
	<link rel="stylesheet" type="text/css" href="dudle.css" title="default"/>
HEAD
	
	$htmlout += '<link rel="alternate"  type="application/atom+xml" href="atom.cgi" />' if File.exists?("atom.cgi")

	$htmlout += "</head><body><h1>dudle</h1>"

if $cgi.include?("create_poll")
	SITE=$cgi["create_poll"].gsub(/^\//,"")
	unless File.exist?(SITE)
		Dir.mkdir(SITE)
		Dir.chdir(SITE)
		VCS.init
		File.symlink("../participate.rb","index.cgi")
		File.symlink("../atom_single.rb","atom.cgi")
		File.symlink("../config_poll.rb","config.cgi")
		File.symlink("../remove_poll.rb","remove.cgi")
		["index.cgi","atom.cgi","config.cgi","remove.cgi"].each{|f|
			VCS.add(f)
		}
		["data.yaml",".htaccess",".htdigest"].each{|f|
			File.open(f,"w").close
			VCS.add(f)
		}
		case $cgi["poll_type"]
		when "create normal poll"
			Poll.new SITE
		when "create event schedule"
			TimePoll.new SITE
		end
		Dir.chdir("..")
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
		$htmlout += "<td class='polls'><a href='./#{CGI.escapeHTML(site).gsub("'","%27")}/'>#{CGI.escapeHTML(site)}</a></td>"
		$htmlout += "<td class='mtime'>#{File.new(site + "/data.yaml").mtime.strftime('%d.%m, %H:%M')}</td>"
		$htmlout += "</tr>"
	end
}
$htmlout += "</table>"
$htmlout += "</fieldset>"

$htmlout += <<CREATE
<fieldset><legend>Create new Poll</legend>
<form method='post' action='.'>
<table>
<tr>
	<td><label title="#{poll_name_tip = "the name equals the link under which you receive the poll"}" for="poll_name">Name:</label></td>
	<td><input title="#{poll_name_tip}" id="poll_name" size='16' type='text' name='create_poll' /></td>
	<td>Type:</td>
	<td class='create_poll'>
		<input type='submit' value='create event schedule' name='poll_type' />
		<br />
		<input type='submit' value='create normal poll' name='poll_type' />
	</td>
</tr>
</table>
</form>
</fieldset>
CREATE

$htmlout += <<CHARSET
<fieldset><legend>change charset</legend>
#{UTFASCII}
</fieldset>
CHARSET


$htmlout += NOTICE
$htmlout += "</body>"

$htmlout += "</html>"

$cgi.out("type" => TYPE ,"charset" => CHARSET,"cookie" => $utfcookie, "Cache-Control" => "no-cache"){$htmlout}
end

