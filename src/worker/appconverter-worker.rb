#!/usr/bin/env ruby
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

CONFIGURATION_FILE   = ETC_LOCATION + "/appconverter-worker.conf"

$: << RUBY_LIB_LOCATION

###############################################################################
# Gems
###############################################################################
require 'rubygems'
require 'yaml'
require 'json'
require 'open3'
require 'pp'

###############################################################################
# Libraries
###############################################################################
require 'appconverter-client'

begin
    CONF = YAML.load_file(CONFIGURATION_FILE)
rescue Exception => e
    STDERR.puts "Error parsing config file #{CONFIGURATION_FILE}: #{e.message}"
    exit 1
end

while true do
    client = AppConverter::Client.new

    # Get next job
    response = client.get('/worker/' + CONF[:worker_name] + '/nextjob')
    if AppConverter::CloudClient.is_error?(response)
        puts response.message
    else
        json_hash = JSON.parse(response.message)

        # TODO check if name script exists
        command = [
            DRIVERS_LOCATION + '/' + json_hash['name'],
            client.url + '/worker/' + CONF[:worker_name] + '/job/' + job_hash['_id']['$oid'],
            response.message].join(' ')

        stdin, stdout, stderr = Open3.popen3(command)
    end

    # TODO Cancel jobs


    # TODO Check if jobs are still in-progress

    sleep CONF[:interval]
end
