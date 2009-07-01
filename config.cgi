#!/usr/bin/env ruby

################################
# Author:  Benjamin Kellermann #
# Licence: CC-by-sa 3.0        #
#          see Licence         #
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

olddir = File.expand_path(".")
Dir.chdir("..")
load "charset.rb"
load "config.rb"
require "poll"
require "datepoll"
Dir.chdir(olddir)

if $cgi.include?("revision")
	REVISION=$cgi["revision"].to_i
	table = YAML::load(VCS.cat(REVISION, "data.yaml"))
else
	table = YAML::load_file("data.yaml")

	table.invite_delete($cgi["invite_delete"])	if $cgi.include?("invite_delete") and $cgi["invite_delete"] != ""
	table.add_remove_column($cgi["add_remove_column"],$cgi["columndescription"]) if $cgi.include?("add_remove_column")
	table.toggle_hidden if $cgi.include?("toggle_hidden")
end
table.init

$htmlout += <<HTMLHEAD
<head>
	<meta http-equiv="Content-Type" content="#{TYPE}; charset=#{CHARSET}" /> 
	<meta http-equiv="Content-Style-Type" content="text/css" />
	<title>dudle - config - #{table.name}</title>
	<link rel="stylesheet" type="text/css" href="../dudle.css" title="default"/>
</head>
<body>
	<div>
		<small>
			<a href='.' style='text-decoration:none'>#{BACK}</a>
			history:#{table.history_to_html}
		</small>
	</div>
HTMLHEAD

$htmlout += <<TABLE
	<h1>#{table.name}</h1>
#{table.to_html(config = true)}
TABLE

$htmlout += <<INVITEDELETE
<div id='invite_delete'>
	<fieldset>
		<legend>invite/delete participant</legend>
		<form method='post' action='config.cgi'>
			<div>
				<input size='16' value='#{$cgi["invite_delete"]}' type='text' name='invite_delete' />
				<input type='submit' value='invite/delete' />
			</div>
		</form>
	</fieldset>
</div>
INVITEDELETE

# ADD/REMOVE COLUMN
$htmlout +=<<ADD_REMOVE
<div id='add_remove_column'>
<fieldset><legend>add/remove column</legend>
#{table.add_remove_column_htmlform}
</fieldset>
</div>
ADD_REMOVE

$htmlout +=<<HIDDEN
<div id='toggle_hidden'>
	<fieldset>
		<legend>Toggle Hidden flag</legend>
		<form method='post' action=''>
			<div>
				<input type='hidden' name='toggle_hidden' value='toggle' />
				<input type='submit' value='#{table.hidden ? "unhide" : "hide"}' />
			</div>
		</form>
	</fieldset>
</div>
HIDDEN

$htmlout += "</body>"

$htmlout += "</html>"

$cgi.out("type" => TYPE ,"charset" => CHARSET,"cookie" => $utfcookie, "Cache-Control" => "no-cache"){$htmlout}
end

