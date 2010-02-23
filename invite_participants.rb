#!/usr/bin/env ruby

############################################################################
# Copyright 2009,2010 Benjamin Kellermann                                  #
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

if __FILE__ == $0

load "../dudle.rb"

$d = Dudle.new

if $cgi.include?("add_participant")
	if $cgi.include?("delete_participant")
		$d.table.delete($cgi["olduser"])
	else
		$d.table.add_participant($cgi["olduser"],$cgi["add_participant"],{})
	end
end

$d.wizzard_redirect

inviteparticipantsstr = _("Invite Participants")
$d << <<TABLE
	<h2>#{inviteparticipantsstr}</h2>
<form method='post' action='invite_participants.cgi' accept-charset='utf-8'>
	#{$d.table.invite_to_html($cgi['edituser'])}
</form>
TABLE

$d.out
end

