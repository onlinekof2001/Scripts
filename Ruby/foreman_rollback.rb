#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'net/http'
require 'net/https'
require 'yaml'

if ARGV.empty?
  puts "Usage: ruby foreman_audit.rb <env> <id> <maxpage>"
  puts "env = preproduction or production"
end

preproduction="theforeman.preprod.org"
production="theforeman.subsidia.org"

session=""

id=ARGV[1].to_i
maxpage=ARGV[2].to_i

if ARGV[0]=="preproduction" then
  session = preproduction
  password =  "85Zy?w?J"
else
  session = production
  password = "jF}M5a}s"
end


(1..maxpage).each { |i|
  uri = URI.parse("https://#{session}/api/audits?page=#{i}&per_page=500")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this

  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth("audituser", password)
  response = http.request(request)

  data=JSON.parse(response.body)
  result=data['results'].select {|e| e['id'] == id}.to_json

  result=JSON.parse(result)
  puts "Looking on page #{i}"
  next if result.empty?
  #abort("No data found. Check your ID") if result.empty?
  
  if result[0]['action'] == "destroy"
    v_before=result[0]['audited_changes']['value']
    v_after=""
  else
    v_before=result[0]['audited_changes']['value'][0]
    v_after=result[0]['audited_changes']['value'][1]
  end

  printf("%-25s%-20s\n","user_name:",result[0]['user_name'] )
  printf("%-25s%-20s\n","associacted_name:",result[0]['associated_name'] )
  printf("%-25s%-20s\n","auditable_name:",result[0]['auditable_name'] )
  puts 
  puts "================================================================================"
  puts "==================================BEFORE========================================"
  puts "================================================================================"
  puts
  puts v_before.to_yaml
  puts
  puts "================================================================================"
  puts "==================================AFTER========================================="
  puts "================================================================================"
  puts
  puts v_after.to_yaml
  puts
  break
}
