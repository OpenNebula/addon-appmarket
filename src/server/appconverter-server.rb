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

$: << RUBY_LIB_LOCATION + '/appconverter'

###############################################################################
# Gems
###############################################################################
require 'rubygems'
require 'sinatra'
require 'yaml'
require 'mongo'

###############################################################################
# Libraries
###############################################################################
require 'lib/job_collection'
require 'lib/app_collection'
require 'lib/parser'
require 'lib/validator'

###############################################################################
# Server Configuration. This is called when the server is started
###############################################################################
configure do
    begin
        CONF = YAML.load_file(CONFIGURATION_FILE)
    rescue Exception => e
        STDERR.puts "Error parsing config file #{CONFIGURATION_FILE}: #{e.message}"
        exit 1
    end

    set :bind, CONF[:host]
    set :port, CONF[:port]

    DB = Mongo::Connection.new(CONF['db_host'], CONF['db_port']).db(APPCONVERTER_DB_NAME)
end

###############################################################################
# Helpers. This methods are called before/after each request
#   All the routes must define the @tmp_response variable containing the
#   status code and the Hash/Array to be formatted and included as body
###############################################################################
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

# Get the jobs collection
get '/job' do
    job_collection = AppConverter::JobCollection.new()
    @tmp_response = job_collection.info
end

# Get a job
get '/job/:id' do
    job = AppConverter::JobCollection.get(params[:id])
    if AppConverter::Collection.is_error?(job)
        @tmp_response = job
    else
        @tmp_response = [200, job.to_hash]
    end
end

# Create a new job
post '/job' do
    @tmp_response = AppConverter::JobCollection.create(@body_hash)
end

# Delete a job
delete '/job/:id' do
    job = AppConverter::JobCollection.get(params[:id])
    if AppConverter::Collection.is_error?(job)
        @tmp_response = job
    else
        @tmp_response = job.delete
    end
end

# TODO Update job

###############################################################################
# Worker
###############################################################################

# Get the jobs collection of the given worker
get '/worker/:worker_host/job' do
    job_selector = {}
    job_selector['worker_host'] = params[:worker_host]
    job_selector['status'] = params[:status] if params[:status]

    job_collection = AppConverter::JobCollection.new(job_selector, {})
    @tmp_response = job_collection.info
end

# Callbacks from the worker to update the given job
#   Available callbacks are defined in AppConverter::Job::CALLBACKS
post '/worker/:worker_host/job/:job_id/:callback' do
    job = AppConverter::JobCollection.get(params[:job_id])
    if AppConverter::Collection.is_error?(job)
        @tmp_response = job
    else
        if AppConverter::Job::CALLBACKS.include?(params[:callback])
            # TODO check @body_hash keys

            @tmp_response = job.send(
                "cb_#{params[:callback]}".to_sym,
                params[:worker_host],
                @body_hash ? @body_hash['job'] : {},
                @body_hash ? @body_hash['appliance'] : {})
        else
            @tmp_response = [403, "Callback #{params[:callback]} not supported"]
        end
    end
end

# Retrieve the next job for the given worker.
get '/worker/:worker_host/nextjob' do
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
        ready_app_ids = app_collection.collect {|app| app['_id'].to_s }

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
                next_job = job_collection.first
                next_job.start(params[:worker_host], {}, {})
                @tmp_response = [200, next_job.to_hash]
            end
        end
    end
end

###############################################################################
# Appliance
###############################################################################

# Get the appliances collecion
get '/appliance' do
    app_collection = AppConverter::AppCollection.new()
    @tmp_response = app_collection.info
end

# Get an appliance
get '/appliance/:id' do
    app = AppConverter::AppCollection.get(params[:id])
    if AppConverter::Collection.is_error?(app)
        @tmp_response = app
    else
        @tmp_response = [200, app.to_hash]
    end
end

# Create an appliance
post '/appliance' do
    @tmp_response = AppConverter::AppCollection.create(@body_hash)
end

# Delete an appliance
delete '/appliance/:id' do
    app = AppConverter::AppCollection.get(params[:id])
    if AppConverter::Collection.is_error?(app)
        @tmp_response = app
    else
        @tmp_response = app.delete
    end
end

# TODO Update appliance
