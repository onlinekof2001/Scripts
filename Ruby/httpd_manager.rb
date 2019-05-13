#!/usr/bin/ruby

require 'rubygems'
require 'net/http'
require 'json'
require 'net/ssh'
require File.join File.dirname(__FILE__),  '../function.rb'
require File.join File.dirname(__FILE__),  '../APACHE/lib.rb'

SSH_USER="rundeck"

unless ARGV.length == 2
      puts "Dude, not the right number of arguments."
      puts "Usage: ruby httpd_manager.rb server action \n"
      exit
end

#real time log for rundeck
$stdout.sync = true

server=ARGV[0]
action=ARGV[1]

case "#{action}"
  when "start"
      ap=APACHE.new(server,SSH_USER)
      ap.startApache()
  when "stop"
      ap=APACHE.new(server,SSH_USER)
      ap.stopApache()
  when "restart"
      ap=APACHE.new(server,SSH_USER)
      ap.restartApache()
  when "status"
      ap=APACHE.new(server,SSH_USER)
      ap.statusApache()
  else
      puts "\t [WARNING]  #{action} not supported"
end