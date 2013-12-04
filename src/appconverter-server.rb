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

require 'rubygems'
require 'sinatra'
require 'yaml'
require 'mongo'

if ENV['RACK_ENV'] == 'test'
    LOG_LOCATION = "/tmp"
    ETC_LOCATION = File.dirname(__FILE__) + '/etc'
    RUBY_LIB_LOCATION = File.dirname(__FILE__)

    APPCONVERTER_DB_NAME = 'appconverter_dev'
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

    APPCONVERTER_DB_NAME = 'appconverter'
end

APPCONVERTER_LOG     = LOG_LOCATION + "/appconverter-server.log"
CONFIGURATION_FILE   = ETC_LOCATION + "/appconverter-server.conf"

$: << RUBY_LIB_LOCATION

require 'lib/job_collection'
require 'lib/app_collection'
require 'helpers/parser'
require 'helpers/validator'

configure do
    begin
        CONF = YAML.load_file(CONFIGURATION_FILE)
    rescue Exception => e
        STDERR.puts "Error parsing config file #{CONFIGURATION_FILE}: #{e.message}"
        exit 1
    end

    DB = Mongo::Connection.new(CONF['db_host'], CONF['db_port']).db(APPCONVERTER_DB_NAME)
end

after do
    content_type :json
    status @tmp_response[0]
    body AppConverter::Parser.generate_body(@tmp_response[1])
end

before do
    if request.body && request.body.size > 0
        # TODO handle exception
        @body_hash = AppConverter::Parser.parse_body(request.body.read)
    end
end

###############################################################################
# Job
###############################################################################

get '/job' do
    job_collection = AppConverter::JobCollection.new({},{:sort => ['_id', Mongo::ASCENDING]})
    @tmp_response = job_collection.info
end

get '/job/:id' do
    job = AppConverter::Job.new(params[:id])
    @tmp_response = job.info
end

post '/job' do
    @tmp_response = AppConverter::JobCollection.create(@body_hash)
end

delete '/job/:id' do
    job = AppConverter::Job.new(params[:id])
    @tmp_response = job.delete
end

###############################################################################
# Worker
###############################################################################

get '/worker/:id/job' do

end

get '/worker/:id/nextjob' do
    # Retrieve the apps with no running jobs
    app_selector = {
        'status' => { '$in' => ['init', 'ready'] }
    }

    app_opts = {
        :fields => {}
    }

    app_collection = AppConverter::AppCollection.new(app_selector, app_opts)
    app_response = app_collection.info

    if AppConverter::Collection.is_error?(app_response)
        @tmp_response = app_response
    else
        # Retrieve the pending jobs that are not associated with any appliance
        #   with a running job
        ready_app_ids = app_response[1].collect {|app| app['_id'].to_s }

        job_selector = {
            'status' => 'pending',
            'appliance_id' => { '$in' => ready_app_ids }
        }

        job_opts = {
            :sort => ['creation_time', Mongo::ASCENDING]
        }

        job_collection = AppConverter::JobCollection.new(job_selector, job_opts)
        job_response = job_collection.info

        if AppConverter::Collection.is_error?(job_response)
            @tmp_response = job_response
        else
            if job_collection.empty?
                @tmp_response = [404, {'message' => "There is no job available"}]
            else
                next_job = job_collection[0]
                next_job.update({
                    'status' => 'in-progress',
                    'worker_host' => params[:id],
                    'start_time' => Time.now.to_i})
                @tmp_response = [200, next_job.to_hash]
            end
        end
    end
end

###############################################################################
# Appliance
###############################################################################

get '/appliance' do
    app_collection = AppConverter::AppCollection.new()
    @tmp_response = app_collection.info
end

get '/appliance/:id' do
    app = AppConverter::Appliance.new(params[:id])
    @tmp_response = app.info
end

post '/appliance' do
    @tmp_response = AppConverter::AppCollection.create(@body_hash)
end

delete '/appliance/:id' do
    app = AppConverter::Appliance.new(params[:id])
    @tmp_response = app.delete
end
