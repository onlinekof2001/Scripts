require 'rubygems'
#require 'net/http'
#require 'json'
require 'net/ssh'
#require 'net/scp'

require File.join File.dirname(__FILE__),  'function.rb'

class OC4J
  def initialize (server,user)
    @server = server
    @user   = user
  end

  def stopOC4J()
    begin
    Net::SSH.start(@server, @user) do |ssh|
      output=ssh_exec!(ssh, "sudo /opt/oracle/as10g01/opmn/bin/opmnctl stopproc process-type=#{item}")
      puts "#{item} stop successed"
    end
    rescue Net::SSH::AuthenticationFailed => e
      puts "[ERROR] #{@server} AUTH ERROR: "+e.message
      return false
    end
  end

  def startOC4J(item)
    begin
    Net::SSH.start(@server, @user) do |ssh|
      output=ssh_exec!(ssh, "sudo /opt/oracle/as10g01/opmn/bin/opmnctl startproc process-type=#{item}")
      puts "#{item} start successed"

      running = false
      while not running
        output=ssh_exec!(ssh, "sudo /opt/oracle/as10g01/opmn/bin/opmnctl status")
        if output[0] =~ /Alive/
          running = true
        else
          puts "\t Starting... (sleep 10s)"
          sleep(10)
        end
      end
	end
    rescue Net::SSH::AuthenticationFailed => e
      puts "[ERROR] #{@server} AUTH ERROR: "+e.message
      return false
    end
  end

  def restartallOC4J()
    begin
    Net::SSH.start(@server, @user) do |ssh|
      output=ssh_exec!(ssh, "sudo /opt/oracle/as10g01/opmn/bin/opmnctl stopall && sudo /opt/oracle/as10g01/opmn/bin/opmnctl startall")
      puts "oc4j start successed"
  end
    rescue Net::SSH::AuthenticationFailed => e
      puts "[ERROR] #{@server} AUTH ERROR: "+e.message
      return false
    end
  end

  def statusAllOC4J()
    begin
    Net::SSH.start(@server, @user) do |ssh|
      output=ssh_exec!(ssh, "sudo /opt/oracle/as10g01/opmn/bin/opmnctl status -fmt %cmp30%prt30%pid7R%sta6%utm10%mem10%")
      puts "SSH #{@server} - Status - \n \t #{output[0]}"
    end
    rescue Net::SSH::AuthenticationFailed => e
      puts "[ERROR] #{@server} AUTH ERROR: "+e.message
      return false
    end
  end

  def checkvsftp()
    begin
    Net::SSH.start(@server, @user) do |ssh|
      output=ssh_exec!(ssh,"pgrep vsftpd")
      return output[2]
    end
  end
  end

  def startvsftp()
    begin
      Net::SSH.start(@server, @user) do |ssh|
        output=ssh_exec!(ssh,"sudo /etc/init.d/vsftpd start")
	puts "SSH #{@server} - status -  \n \t #{output[0]}"
      end
    end
  end

  def stopvsftp()
    begin
      Net::SSH.start(@server, @user) do |ssh|
        output=ssh_exec!(ssh,"sudo /etc/init.d/vsftpd stop")
	puts "SSH #{@server} - status -  \n \t #{output[0]}"
      end
    end
  end

end
