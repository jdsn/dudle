#!/usr/bin/env ruby

################################
# Author:  Benjamin Kellermann #
# Licence: CC-by-sa 3.0        #
#          see Licence         #
################################

require "rubygems"
require "atom"
require "yaml"
require "cgi"
require "time"

$cgi = CGI.new

def readhistory dir
	log = `export LC_ALL=de_DE.UTF-8; bzr log -r -10.. "#{dir}"`.split("-"*60)
	log.collect!{|s| s.scan(/\nrevno: (.*)\ncommitter.*\n.*\ntimestamp: (.*)\nmessage:\n  (.*)/).flatten}
	log.shift
	log.collect!{|r,t,c| [r.to_i,Time.parse(t),c]}
end

feed = Atom::Feed.new 
if File.exist?("data.yaml")
	olddir = File.expand_path(".")
	Dir.chdir("..")
	load "config.rb"
	require "poll"
	require "datepoll"
	require "timepoll"
	Dir.chdir(olddir)

	poll = YAML::load_file("data.yaml")

	feed.title = poll.name
	feed.id = "urn:dudle:#{poll.class}:#{poll.name}"
	feed.updated = File.new("data.yaml").mtime
	feed.authors << Atom::Person.new(:name => 'dudle automatic notificator')
	feed.links << Atom::Link.new(:href => SITEURL + "atom.cgi", :rel => "self")

	log = readhistory "."
	log.each {|rev,time,comment|	
		feed.entries << Atom::Entry.new do |e|	
			e.title = comment
			e.links << Atom::Link.new(:href => "#{SITEURL}?revision=#{rev}")
			e.id = "urn:#{poll.class}:#{poll.name}:rev=#{rev}"
			e.updated = time
		end
	}

else
	load "config.rb"
	require "poll"
	require "datepoll"
	require "timepoll"
	feed.title = "dudle"
	feed.id = "urn:dudle:main"
	feed.authors << Atom::Person.new(:name => 'dudle automatic notificator')
	feed.links << Atom::Link.new(:href => SITEURL + "atom.cgi", :rel => "self")
	
	Dir.glob("*/data.yaml").sort_by{|f|
		File.new(f).mtime
	}.reverse.collect{|f|
		f.gsub(/\/data\.yaml$/,'')
	}.each{|site|
		unless YAML::load_file("#{site}/data.yaml" ).hidden
			unless defined?(firstround)
				firstround = false
				feed.updated = File.new("#{site}/data.yaml").mtime
			end
			
			log = readhistory(site)
			log.each {|rev,time,comment|
				feed.entries << Atom::Entry.new do |e|
					e.title = site
					e.summary = comment
					e.links << Atom::Link.new(:href => "#{SITEURL}#{site}/?revision=#{rev}")
					e.id = "urn:dudle:main:#{site}:rev=#{rev}"
					e.updated = time
				end
			}
		end
	}

end

$cgi.out("type" => "application/atom+xml"){ feed.to_xml }
