require 'rubygems'
require 'net/ssh'

require File.join File.dirname(__FILE__),  'function.rb'

JMX_CLIENT="jmxterm-1.0-alpha-4-uber.jar"
JMX_LOCAL_DIR=File.dirname(__FILE__)
JMX_DIST_DIR="/tmp"
JAVA_BIN="/opt/jdk/bin/java"

class INST
    def initialize (server,user)
        @server = server
        @user   = user
    end

    def actionINST(item,operation)
        begin
            Net::SSH.start(@server, @user) do |ssh|
            output=ssh_exec!(ssh, "sudo /usr/bin/systemctl #{operation} tomcat@#{item}")
            puts "\n \t #{output[0]}"
            if "#{operation}" =~ /start/ && "#{item}" == 'FLUX01'
                outp=ssh_exec!(ssh, "sudo /usr/bin/systemctl status tomcat@#{item}")
                puts "#{@server} - #{item} - #{operation} \n#{outp[0]}"
            end
        end
        rescue Net::SSH::AuthenticationFailed => e
            puts "[ERROR] #{@server} AUTH ERROR: "+e.message
            return false
        end
    end

    def actionBATC(item,operation)
        begin
            Net::SSH.start(@server, @user) do |ssh|
            osver=ssh_exec!(ssh, "cat /etc/redhat-release | awk '{print $(NF-1)}' | awk -F'.' '{print $1}'")
            if "#{osver[0]}" < '7'
                output=ssh_exec!(ssh, "sudo /etc/init.d/bcd_#{item} #{operation}")
                puts "\n \t #{output[0]}"
                if "#{operation}" =~ /start/ && "#{item}" =~ /BCSTORES/
                    outp=ssh_exec!(ssh, "sudo /etc/init.d/bcd_#{item} status")
                    puts "#{@server} - #{item} - #{operation} \n#{outp[0]}"
                end
            else
                output=ssh_exec!(ssh, "sudo /usr/bin/systemctl #{operation} bcd@#{item}")
                puts "\n \t #{output[0]}"
                if "#{operation}" =~ /start/ && "#{item}" =~ /BCSTORES/
                    outp=ssh_exec!(ssh, "sudo /usr/bin/systemctl status bcd@#{item}")
                    puts "#{@server} - #{item} - #{operation} \n#{outp[0]}"
                end
            end
        end
        rescue Net::SSH::AuthenticationFailed => e
            puts "[ERROR] #{@server} AUTH ERROR: "+e.message
            return false
        end
    end

    def pauseBatchconsole(item)
        begin
            Net::SSH.start(@server, @user) do |ssh|
            jmxoutput=ssh_exec!(ssh, "cat /opt/#{item}/config/jmx-service-url.txt")
            @bcurl=jmxoutput[0]
            jmxcommand="run -b com.saltoconsulting.console.admin:name=scheduler,type=scheduler getStatus"
            output=ssh_exec!(ssh, "echo #{jmxcommand} | sudo #{JAVA_BIN} -jar #{JMX_DIST_DIR}/#{JMX_CLIENT} --url #{@bcurl} -u dev -p dev -n -v silent")
            if output[0].strip == "RUNNING"
                jmxcommand="run -b com.saltoconsulting.console.admin:name=scheduler,type=scheduler pause"
                output=ssh_exec!(ssh, "echo #{jmxcommand} | sudo #{JAVA_BIN} -jar #{JMX_DIST_DIR}/#{JMX_CLIENT} --url #{@bcurl} -u dev -p dev -n -v silent")
                abort "\t #{output[0]}\n Error when executing jmx command"  unless output[0].strip == "SUCCESS"

                jmxcommand="run -b com.saltoconsulting.console.admin:name=scheduler,type=scheduler getStatus"
                output=ssh_exec!(ssh, "echo #{jmxcommand} | sudo #{JAVA_BIN} -jar #{JMX_DIST_DIR}/#{JMX_CLIENT} --url #{@bcurl} -u dev -p dev -n -v silent")
                abort "\t #{output[0]}\n Error when executing jmx command"  unless output[0].strip == "PAUSED"

                puts "SSH #{@server} - #{item} \n \t #{output[0]}"
            else
                puts "\t Not running... skip action"
            end
        end
        rescue Net::SSH::AuthenticationFailed => e
        puts "SSH #{@server} - #{item} \n [ERROR] #{@server} AUTH ERROR: "+e.message
        return false
        end
    end

    def resumeBatchconsole(item)
        begin
            Net::SSH.start(@server, @user) do |ssh|
            jmxoutput=ssh_exec!(ssh, "cat /opt/#{item}/config/jmx-service-url.txt")
            @bcurl=jmxoutput[0]
            jmxcommand="run -b com.saltoconsulting.console.admin:name=scheduler,type=scheduler getStatus"
            output=ssh_exec!(ssh, "echo #{jmxcommand} | sudo #{JAVA_BIN} -jar #{JMX_DIST_DIR}/#{JMX_CLIENT} --url #{@bcurl} -u dev -p dev -n -v silent")
    
            if output[0].strip == "PAUSED"
                jmxcommand="run -b com.saltoconsulting.console.admin:name=scheduler,type=scheduler resume"
                output=ssh_exec!(ssh, "echo #{jmxcommand} | sudo #{JAVA_BIN} -jar #{JMX_DIST_DIR}/#{JMX_CLIENT} --url #{@bcurl} -u dev -p dev -n -v silent")
                abort "\t #{output[0]}\n Error when executing jmx command"  unless output[0].strip == "SUCCESS"

                jmxcommand="run -b com.saltoconsulting.console.admin:name=scheduler,type=scheduler getStatus"
                output=ssh_exec!(ssh, "echo #{jmxcommand} | sudo #{JAVA_BIN} -jar #{JMX_DIST_DIR}/#{JMX_CLIENT} --url #{@bcurl} -u dev -p dev -n -v silent")
                abort "\t #{output[0]}\n Error when executing jmx command"  unless output[0].strip == "RUNNING"

                puts "SSH #{@server} - #{item} \n \t #{output[0]}"
            else
                puts "SSH #{@server} - #{item} \n \t Already running... skip action"
            end
        end
        rescue Net::SSH::AuthenticationFailed => e
        puts "SSH #{@server} - #{item} \n [ERROR] #{@server} AUTH ERROR: "+e.message
        return false
        end
    end

end
