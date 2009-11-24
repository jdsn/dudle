#!/usr/bin/env ruby

############################################################################
# Copyright 2009 Benjamin Kellermann                                       #
#                                                                          #
# This file is part of dudle.                                              #
#                                                                          #
# Dudle is free software: you can redistribute it and/or modify it under   #
# the terms of the GNU Affero General Public License as published by       #
# the Free Software Foundation, either version 3 of the License, or        #
# (at your option) any later version.                                      #
#                                                                          #
# Dudle is distributed in the hope that it will be useful, but WITHOUT ANY #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or        #
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public     #
# License for more details.                                                #
#                                                                          #
# You should have received a copy of the GNU Affero General Public License #
# along with dudle.  If not, see <http://www.gnu.org/licenses/>.           #
############################################################################

require "cgi"

if __FILE__ == $0

$cgi = CGI.new

olddir = File.expand_path(".")
Dir.chdir("..")
load "html.rb"
load "config.rb"
Dir.chdir(olddir)

POLL = File.basename(File.expand_path("."))
$html = HTML.new("dudle - #{POLL} - Access Control Settings")
$html.header["Cache-Control"] = "no-cache"

acusers = {}

File.open(".htdigest","r").each_line{|l| 
	user,realm = l.scan(/^(.*):(.*):.*$/).flatten
	acusers[user] = realm
}

def write_htaccess(acusers)
	File.open(".htaccess","w"){|htaccess|
		if acusers.values.include?("config")
			htaccess << <<HTACCESS
<Files ~ "^(edit_columns|invite_participants|access_control|delete_poll).cgi$">
AuthType digest
AuthName "config"
AuthUserFile "#{File.expand_path(".").gsub('"','\\\\"')}/.htdigest"
Require valid-user
</Files>
HTACCESS
		end
		if acusers.values.include?("vote")
			htaccess << <<HTACCESS
AuthType digest
AuthName "vote"
AuthUserFile "#{File.expand_path(".").gsub('"','\\\\"')}/.htdigest"
Require valid-user
HTACCESS
			VCS.commit("Access Control changed")
		end
	}
	unless acusers.empty?
		$html.header["status"] = "REDIRECT"
		$html.header["Cache-Control"] = "no-cache"
		$html.header["Location"] = "access_control.cgi"
	end
end
def add_to_htdigest(user,type,password)
	fork {
		IO.popen("htdigest .htdigest #{type} #{user}","w+"){|htdigest|
			htdigest.sync
			htdigest.puts(password)
			htdigest.puts(password)
		}
	}
end

def createform(userarray,hint,acusers,newuser)
	ret = <<FORM
<form method='post' action='' >
	<table summary='Enter Access Control details' class='settingstable'>
		<tr>
			<td class='label'>Username:</td>
			<td title="#{userarray[2]}">
				#{userarray[0]}
				<input type='hidden' name='ac_user' value='#{userarray[0]}' /></td>
				<input type='hidden' name='ac_type' value='#{userarray[1]}' /></td>
			</td>
		</tr>
FORM

	2.times{|i|
		ret += <<PASS
		<tr>
			<td class='label'><label for='password#{i}'>Password#{i == 1 ? " (repeat)" : ""}:</label></td>
			<td>
PASS
		if newuser
			ret += "<input id='password#{i}' size='6' value='' type='password' name='ac_password#{i}' />"
		else
			ret += PASSWORDSTAR*14
		end
		ret += "</td></tr>"
	}

	ret += <<FORM
	<tr>
		<td></td>
		<td class='shorttextcolumn'>#{newuser ? hint : ""}</td>
	</tr>
	<tr>
		<td></td>
		<td>
FORM
	if newuser
		ret += "<input type='submit' name='ac_create' value='Save' />"
	else
		ret += "<input type='submit' name='ac_delete_#{userarray[0]}' value='Delete' />"
	end

	ret += <<FORM
				<input type='hidden' name='ac_activate' value='Activate' />
			</td>
		</tr>
	</table>
</form>
FORM
	ret
end


if $cgi.include?("ac_user")
	user = $cgi["ac_user"]
	type = $cgi["ac_type"]
	if !(user =~ /^[\w]*$/)
		# add user
		usercreatenotice = "<div class='error'>Only uppercase, lowercase, digits are allowed in the username.</div>"
	elsif $cgi["ac_password0"] != $cgi["ac_password1"]
		usercreatenotice = "<div class='error'>Passwords did not match.</div>"
	else
		if $cgi.include?("ac_create")
			case type 
			when "config" 
				add_to_htdigest(user, type, $cgi["ac_password0"])
				add_to_htdigest(user, "vote", $cgi["ac_password0"])
				acusers[user] = type 
				write_htaccess(acusers)
			when "vote"
				add_to_htdigest(user, type, $cgi["ac_password0"])
				acusers[user] = type 
				write_htaccess(acusers)
			end
		end

		# delete user
		deleteuser = ""
		acusers.each{|user,action|
			if $cgi.include?("ac_delete_#{user}")
				deleteuser = user
			end
		}
		acusers.delete(deleteuser)
		htdigest = []
		File.open(".htdigest","r"){|file|
			htdigest = file.readlines
		}
		File.open(".htdigest","w"){|f|
			htdigest.each{|line|
				f << line unless line =~ /^#{deleteuser}:/
			}
		}
		write_htaccess(acusers)
	end
end

unless $html.header["status"] == "REDIRECT"

load "../charset.rb"
$html.add_css("../dudle.css")

$html << "<body>"
$html << Dudle::tabs("Access Control")

$html << <<HEAD
<div id='main'>
	<h1>#{POLL}</h1>
	<h2>Change Access Control Settings</h2>
HEAD

if acusers.empty? && $cgi["ac_activate"] != "Activate"

	acstatus = ["red","not activated"]
	acswitchbutton = "<input type='submit' name='ac_activate' value='Activate' />"
else
	if acusers.empty?
		acstatus = ["blue","will be activated when at least an admin user is configured"]
	else
		acstatus = ["green", "activated"]
	end
	acswitchbutton = "<input type='submit' name='ac_activate' value='Deactivate' />"


	admincreatenotice = usercreatenotice || "You will be asked for the password you entered here after pressing save!"

	user = ["admin","config",
	        "The user ‘admin’ has access to the vote as well as the configuration interface."]
	adminexists = acusers.include?(user[0])

	createform = createform(user,usercreatenotice,acusers,!adminexists)
	if adminexists
		participantcreatenotice = usercreatenotice || ""
		user = ["participant","vote",
	        "The user ‘participant’ has only access to the vote interface."]
		participantexists = acusers.include?(user[0])
	  createform += createform(user,participantcreatenotice,acusers,!participantexists)
	end

end

$html << <<AC
<form method='post' action='' >
<table summary='Enable Access Control settings' class='settingstable'>
	<tr>
		<td>
			Access control:
		</td>
		<td style='color: #{acstatus[0]}'>
			#{acstatus[1]}
		</td>
	</tr>
	<tr>
		<td></td>
		<td>
			#{acswitchbutton}	
		</td>
	</tr>
</table>
</form>

#{createform}
AC

$html << "</div></body>"
end

$html.out($cgi)
end
