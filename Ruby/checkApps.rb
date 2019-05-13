#!/usr/bin/ruby

require 'rubygems'
require 'net/http'
require 'json'
require 'net/ssh'
require 'net/scp'


SSH_USER="rundeck"

require File.join File.dirname(__FILE__), '../function.rb'
require File.join File.dirname(__FILE__),  '../TOMCAT/lib.rb'

unless ARGV.length == 5
  puts "Dude, not the right number of arguments."
  puts "Usage: ruby checkApps.rb apps environment platform filter type\n"
  puts "type can be checkApps.sh or checkPool.sh"
  exit
end

#real iatime log for rundeck
$stdout.sync = true

apps=ARGV[0]
env=ARGV[1]
plat=ARGV[2]
filter=ARGV[3]
type=ARGV[4]

abort "Bad type #{type} \n" if type != "checkPool.sh" && type != "checkApps.sh"

url = URI.parse("http://127.0.0.1:4567/serversByAppsEnvPlatf?Application=#{apps}&&Environment=#{env}&&Platform=#{plat}".gsub(' ', '%20'))
req = Net::HTTP::Get.new(url.to_s)
res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
}


json=JSON.parse(res.body)
abort "[ERROR] Empty result from DTC webservice. Please check your params and DTC" if json.nil? || json.empty?

json.each { |v|
  next if not v['Type'] =~ /tomcat/
  next if not v['Itemname'] =~ /#{filter}/

  puts "\nStart check on #{v['Servername']} - #{v['Itemname']}"

  Net::SSH.start(v['Servername'], SSH_USER) do |ssh|
    tc=TOMCAT.new(v['Servername'],SSH_USER,v['Itemname'])
    tc.checkAppsTomcat(type)
  end #net-ssh
}

