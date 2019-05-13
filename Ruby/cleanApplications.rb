#!/usr/bin/ruby

require 'rubygems'
require 'net/http'
require 'json'
require 'net/ssh'
require 'net/scp'


SSH_USER="rundeck"

require File.join File.dirname(__FILE__), '../function.rb'

unless ARGV.length == 5
  puts "Dude, not the right number of arguments."
  puts "Usage: ruby cleanApplications.rb apps environment platform filter\n"
  puts "URL = nexus or direct path"
  exit
end

#real iatime log for rundeck
$stdout.sync = true

apps=ARGV[0]
env=ARGV[1]
plat=ARGV[2]
filter=ARGV[3]
dryrunarg=ARGV[4]

dryrun=true if dryrunarg == true || dryrunarg =~ (/^(true|t|yes|y|1)$/i)
dryrun=false if dryrunarg == false || dryrunarg =~ (/^(false|f|no|n|0)$/i)

url = URI.parse("http://127.0.0.1:4567/serversByAppsEnvPlatf?Application=#{apps}&&Environment=#{env}&&Platform=#{plat}".gsub(' ', '%20'))
req = Net::HTTP::Get.new(url.to_s)
res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
}

json=JSON.parse(res.body)

json.each { |v|
  next if not v['Type'] =~ /tomcat/
  next if not v['Itemname'] =~ /#{filter}/

  puts "\nStart clean on #{v['Servername']} - #{v['Itemname']}"

  Net::SSH.start(v['Servername'], SSH_USER) do |ssh|
    if dryrun
      puts "DRYRUN MODE: On"
      puts "\t Removing /opt/tomcat-servers/#{v['Itemname']}/applications/#{apps}"
      puts "\t Removing find /opt/tomcat-servers/#{v['Itemname']}/applications/ -type f -name '#{apps}*.ear"
      output=ssh_exec!(ssh,"cd /tmp && sudo -u tomcat find /opt/tomcat-servers/#{v['Itemname']}/applications/ -type f -name '#{apps}*.ear'")
      abort "\t #{output[0]}\n find error" unless output[2] == 0
      puts "\t\t#{output[0]}"
      puts "\t Removing /opt/tomcat-servers/#{v['Itemname']}/webapps/#{apps}"
      puts "\t Removing /opt/tomcat-servers/#{v['Itemname']}/conf/Catalina/localhost/#{apps}.xml"
    else
      puts "DRYRUN MODE: Off"
      puts "\t Removing /opt/tomcat-servers/#{v['Itemname']}/applications/#{apps}"
      output=ssh_exec!(ssh,"sudo -u tomcat rm -rf /opt/tomcat-servers/#{v['Itemname']}/applications/#{apps}")
      abort "\t #{output[0]}\n rm error" unless output[2] == 0

      puts "\t Removing /opt/tomcat-servers/#{v['Itemname']}/applications/#{apps}-*.ear"
      output=ssh_exec!(ssh,"cd /tmp && sudo -u tomcat find /opt/tomcat-servers/#{v['Itemname']}/applications/ -type f -name '#{apps}*.ear' -delete")
      puts output[0]
      abort "\t #{output[0]}\n rm error" unless output[2] == 0

      puts "\t Removing /opt/tomcat-servers/#{v['Itemname']}/webapps/#{apps}"
      output=ssh_exec!(ssh,"sudo -u tomcat rm -rf /opt/tomcat-servers/#{v['Itemname']}/webapps/#{apps}")
      abort "\t #{output[0]}\n rm error" unless output[2] == 0

      puts "\t Removing /opt/tomcat-servers/#{v['Itemname']}/conf/Catalina/localhost/#{apps}.xml"
      output=ssh_exec!(ssh,"sudo -u tomcat rm -f /opt/tomcat-servers/#{v['Itemname']}/conf/Catalina/localhost/#{apps}.xml")
      abort "\t #{output[0]}\n rm error" unless output[2] == 0

    end
    
  end #net-ssh
}

