require 'rubygems'
require 'net/http'
require 'json'
require 'net/ssh'
require File.join File.dirname(__FILE__),  'function.rb'
require File.join File.dirname(__FILE__),  'tom_lib.rb'

SSH_USER="rundeck"

unless ARGV.length == 3
  puts "Dude,not the right number of arguments."
  puts "Usage: operaion_instance.rb servername itemname operation\n"
  exit
end

#real time log for rundeck
$stdout.sync = true

serlist=ARGV[0]
item=ARGV[1]
operation=ARGV[2]

serlist.split('&').each do |server|
url = URI.parse("http://127.0.0.1:4567/getInfoByServerAndItem?name=#{item}&&server=#{server}".gsub(' ', '%20'))
req = Net::HTTP::Get.new(url.to_s)
res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
}

#just keep the first apps.
v=JSON.parse(res.body)[0]

puts "ssh #{server} - #{operation} - #{v['Type']}"
if item =~ /BCSTORES/
    case [ v['Type'], operation]
        when ["console","status"]
            tomcat=INST.new(server,SSH_USER)
            tomcat.actionBATC(item,operation)
        when ["console","start"]
            tomcat=INST.new(server,SSH_USER)
            tomcat.actionBATC(item,operation)
        when ["console","stop"]
            tomcat=INST.new(server,SSH_USER)
            tomcat.actionBATC(item,operation)
        when ["console","pause"]
            tomcat=INST.new(server,SSH_USER)
            tomcat.pauseBatchconsole(item)
        when ["console","resume"]
            tomcat=INST.new(server,SSH_USER)
            tomcat.resumeBatchconsole(item)
        else
            puts "\t [WARNING] #{v['Type']} #{operation} not supported"
    end
else
    case [ v['Type'], operation]
        when ["tomcat","#{operation}"]
            tomcat=INST.new(server,SSH_USER)
            tomcat.actionINST(item,operation)
        else
            puts "\t [WARNING] #{v['Type']} #{operation} not supported"
    end
end
end
