# -------------------------------------------------------------------------- #
# Copyright 2002-2013, OpenNebula Project (OpenNebula.org), C12G Labs        #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

###############################################################################
# ENV Configuration
###############################################################################
if ENV['RACK_ENV'] == 'test'
    LOG_LOCATION = "/tmp"
    ETC_LOCATION = File.dirname(__FILE__) + '/etc'
    RUBY_LIB_LOCATION = File.dirname(__FILE__) + '/lib'
    DRIVERS_LOCATION = File.dirname(__FILE__) + '/drivers'
else
    ONE_LOCATION = ENV["ONE_LOCATION"]

    if !ONE_LOCATION
        LOG_LOCATION = "/var/log/one"
        ETC_LOCATION = "/etc/one"
        RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
    else
        LOG_LOCATION = ONE_LOCATION + "/var"
        ETC_LOCATION = ONE_LOCATION + "/etc"
        RUBY_LIB_LOCATION = ONE_LOCATION+"/lib/ruby"
    end
end

JOBS_DIR           = '/var/tmp'
DRIVERS_LOCATION   = RUBY_LIB_LOCATION + '/appconverter/drivers'
CONFIGURATION_FILE = ETC_LOCATION + "/appconverter-worker.conf"

$: << RUBY_LIB_LOCATION + '/appconverter'
$: << RUBY_LIB_LOCATION + '/oneapps/market'
$: << RUBY_LIB_LOCATION + '/cloud'

###############################################################################
# Gems
###############################################################################
require 'rubygems'
require 'yaml'
require 'json'
require 'open4'
require 'base64'
require 'fileutils'

###############################################################################
# Libraries
###############################################################################
require 'appmarket_client'

def get_job_dir(json_hash)
    return JOBS_DIR + '/' + json_hash['_id']['$oid']
end

def exec_job(json_hash)
    job_dir = get_job_dir(json_hash)
    FileUtils.mkdir_p(job_dir)

    callback_url = $client.callback_url(
        CONF[:worker_name], json_hash['_id']['$oid'])
    # TODO check if name script exists
    command = [
        DRIVERS_LOCATION + '/' + json_hash['name'],
        callback_url,
        '"'+Base64.encode64(json_hash.to_json)+'"'].join(' ')

    pid, stdin, stdout, stderr = Open4.popen4(command)

    File.open(job_dir + '/pid', 'w+') { |f|
        f.write(pid)
    }

    Thread.new do
        ignored, status = Process::waitpid2 pid

        if !status.success?
            # TODO if a process is cancelled a signal is sent and this method
            #   will be executed
            # $client.callback(callback_url, 'error')
        end

        if CONF[:debug] == true
            File.open(job_dir + '/stdout', 'w+') { |f|
                f.write(stdout.read.strip)
            }

            File.open(job_dir + '/stderr', 'w+') { |f|
                f.write(stderr.read.strip)
            }
        end
    end
end

def kill_job(json_hash)
    pid_to_be_killed = File.read(get_job_dir(json_hash) + '/pid')
    begin
        Process.kill("INT", pid_to_be_killed.to_i)
    rescue Errno::ESRCH
        puts "PID:#{pid_to_be_killed} No such process"
    end
end

begin
    CONF = YAML.load_file(CONFIGURATION_FILE)
rescue Exception => e
    STDERR.puts "Error parsing config file #{CONFIGURATION_FILE}: #{e.message}"
    exit 1
end

["INT", "TERM"].each { |s|
    trap(s) do
        # TODO cancel running jobs?
        $exit = true
    end
}

$client = AppMarket::Client.new(CONF[:username], CONF[:password], CONF[:url])

while !$exit do
    response = $client.get_next_job(CONF[:worker_name])
    if AppMarket.is_error?(response)
        puts response.message
    else
        json_hash = JSON.parse(response.body)
        exec_job(json_hash)
    end

    response = $client.get_worker_jobs(
        CONF[:worker_name],
        'status' => 'cancelling')

    if AppMarket.is_error?(response)
        puts response.message
    else
        json_array = JSON.parse(response.body)
        json_array.each { |json_hash|
            kill_job(json_hash)

            $client.callback(
                $client.callback_url(
                    CONF[:worker_name], json_hash['_id']['$oid']),
                'cancel')
        }
    end

    STDOUT.flush
    sleep CONF[:interval]
end
