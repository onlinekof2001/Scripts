#!/usr/bin/ruby

require 'rubygems'
require 'net/http'
require 'json'
require 'net/ssh'
require File.join File.dirname(__FILE__),  'function.rb'
require File.join File.dirname(__FILE__),  'oc4j_lib.rb'

SSH_USER="rundeck"

unless ARGV.length == 3
  puts "Dude,not the right number of arguments."
  puts "Usage: ruby oc4j.rb servername itemname operation\n"
  exit
end

#real time log for rundeck
$stdout.sync = true

server=ARGV[0]
item=ARGV[1]
operation=ARGV[2]

url = URI.parse("http://127.0.0.1:4567/getInfoByServerAndItem?name=#{item}&&server=#{server}".gsub(' ', '%20'))
req = Net::HTTP::Get.new(url.to_s)
res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
}

#just keep the first apps.
v=JSON.parse(res.body)[0]

puts "ssh #{v['Servername']} - #{operation} - #{v['Type']}"
case [ v['Type'], operation]
   when ["oc4j","status"]
      oc4j=OC4J.new(v['Servername'],SSH_USER)
      oc4j.statusAllOC4J()
   when ["oc4j","stop"]
      oc4j=OC4J.new(v['Servername'],SSH_USER)
      oc4j.stopOC4J()
   when ["oc4j","start"]
      oc4j=OC4J.new(v['Servername'],SSH_USER)
      oc4j.startOC4J(item)
   else
      puts "\t [WARNING] #{v['Type']} #{operation} not supported"
end
