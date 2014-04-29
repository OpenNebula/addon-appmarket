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
require 'haml'
require 'redcarpet'

ONE_LOCATION = ENV["ONE_LOCATION"]

if !ONE_LOCATION
    LOG_LOCATION = "/var/log/one"
    VAR_LOCATION = "/var/lib/one"
    ETC_LOCATION = "/etc/one"
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
else
    VAR_LOCATION = ONE_LOCATION + "/var"
    LOG_LOCATION = ONE_LOCATION + "/var"
    ETC_LOCATION = ONE_LOCATION + "/etc"
    RUBY_LIB_LOCATION = ONE_LOCATION+"/lib/ruby"
end

APPMARKET_LOG      = LOG_LOCATION + "/appmarket-server.log"

$: << RUBY_LIB_LOCATION
$: << RUBY_LIB_LOCATION+'/cloud'
$: << RUBY_LIB_LOCATION+'/oneapps/market'

require 'models'
require 'session'
require 'parser'
require 'mailer'

require 'pp'

configure do
    set :views,  File.join(File.dirname(__FILE__), '..', 'views')

    if settings.respond_to? :public_folder
        set :public_folder, File.join(File.dirname(__FILE__), '..', 'public')
    else
        set :public, File.join(File.dirname(__FILE__), '..', 'public')
    end

    # Initialize DB with admin credentials
    if AppMarket::UserCollection.new(nil).info[1].empty?
        STDOUT.puts "Bootstraping DB"

        AppMarket::UserCollection.bootstrap(AppMarket::CONF['user'])
        AppMarket::DBVersioning::insert_db_version(AppMarket::VERSION, AppMarket::VERSION_CODE)
    end

    version_codes = AppMarket::DBVersioning::get_version_codes
    if version_codes.empty? || (version_codes.last < AppMarket::VERSION_CODE)
        STDERR.puts "Version mismatch, upgrade required. \n"\
            "DB VERSION: #{version_codes.last||10000}\n" \
            "AppMarket VERSION: #{AppMarket::VERSION_CODE}\n" \
            "Run the 'appmarket-db' command"
        exit 1
    end


    set :bind, AppMarket::CONF[:host]
    set :port, AppMarket::CONF[:port]

    set :root_path, (AppMarket::CONF[:proxy_path]||'/')

    set :config, AppMarket::CONF
end

use Rack::Session::Pool, :key => 'appmarket'

helpers do
    def build_session
        @session = Session.new(request.env)

        if params[:remember] == "true"
            env['rack.session.options'][:expire_after] = 30*60*60*24
        end

        session[:ip] = request.ip
        session[:instance] = @session
    end
end


before do
    if request.env['PATH_INFO'] == '/'
        redirect to(settings.root_path + 'appliance')
    end

    if request.path != '/login' && request.path != '/logout'
        if session[:ip] && session[:ip]==request.ip
            @session = session[:instance]
        else
            build_session
        end

        unless @session.authorize(request.env)
            if request.env["HTTP_ACCEPT"] && request.env["HTTP_ACCEPT"].split(',').grep(/text\/html/).empty?
                error 401, Parser.generate_body("message" => "User not authorized")
            else
                redirect to(settings.root_path + 'appliance')
            end
        end
    end
end

after do
    STDERR.flush
    STDOUT.flush
end

#
# Login
#

post '/login' do
    build_session
    halt 401, Parser.generate_body("message" => "User not authorized") if @session.anonymous?
end

post '/logout' do
    session.clear
    redirect to(settings.root_path + 'appliance')
end


###############################################################################
# Job
###############################################################################

# Get the jobs collection
get '/job' do
    job_collection = AppMarket::JobCollection.new(@session)
    @tmp_response = job_collection.info
    content_type :json
    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

# Get a job
get '/job/:id' do
    job = AppMarket::JobCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(job)
        @tmp_response = job
    else
        @tmp_response = [200, job.to_hash]
    end
    content_type :json
    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

# Create a new job
post '/job' do
    begin
        @tmp_response = AppMarket::JobCollection.create(
                            @session,
                            Parser.parse_body(request))
    rescue JSON::ParserError
        error $!.message
    end

    content_type :json
    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

# Delete a job
delete '/job/:id' do
    job = AppMarket::JobCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(job)
        @tmp_response = job
    else
        if job["status"] == "in-progress"
            @tmp_response = job.cancel
        else
            @tmp_response = job.delete
        end
    end
    content_type :json
    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

###############################################################################
# Worker
###############################################################################

# Get the jobs collection of the given worker
get '/worker/:worker_host/job' do
    job_selector = {}
    job_selector['worker_host'] = params[:worker_host]
    job_selector['status'] = params[:status] if params[:status]

    job_collection = AppMarket::JobCollection.new(@session, job_selector, {})
    @tmp_response = job_collection.info
    content_type :json
    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

# Callbacks from the worker to update the given job
#   Available callbacks are defined in AppMarket::Job::CALLBACKS
post '/worker/:worker_host/job/:job_id/:callback' do
    begin
        @body_hash = Parser.parse_body(request)
    rescue JSON::ParserError
        error $!.message
    end

    job = AppMarket::JobCollection.get(@session, params[:job_id])
    if AppMarket::Collection.is_error?(job)
        @tmp_response = job
    else
        if AppMarket::Job::CALLBACKS.include?(params[:callback])
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
    content_type :json
    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
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

    app_collection = AppMarket::AppCollection.new(@session, app_selector, app_opts)
    app_response = app_collection.info

    if AppMarket::Collection.is_error?(app_response)
        @tmp_response = app_response
    else
        # Retrieve the pending jobs that are not associated with any appliance
        #   with a running job
        ready_app_ids = app_collection.collect {|app| app['_id'].to_s }

        # Retrieve the apps with jobs in progress
        job_selector = {'status' => 'in-progress'}
        jobs_in_progress = AppMarket::JobCollection.new(@session, job_selector,{}) #, {:fields => ['appliance_id']})
        jobs_in_progress_response = jobs_in_progress.info

        if AppMarket::Collection.is_error?(jobs_in_progress_response)
            @tmp_response = jobs_in_progress_response
        else
            apps_in_progress_ids = jobs_in_progress.collect {|job| job['appliance_id'].to_s }

            job_selector = {
                'status' => 'pending',
                'appliance_id' => { '$nin' => apps_in_progress_ids }
            }

            job_opts = {
                :sort => ['creation_time', Mongo::ASCENDING]
            }

            job_collection = AppMarket::JobCollection.new(@session, job_selector, job_opts)
            job_response = job_collection.info

            if AppMarket::Collection.is_error?(job_response)
                @tmp_response = job_response
            else
                if job_collection.empty?
                    @tmp_response = [404, {'message' => "There is no job available"}]
                else
                    next_job = job_collection.first
                    next_job.start(params[:worker_host], {}, {})

                    job_hash = next_job.to_hash
                    @tmp_response = [200, job_hash]
                end
            end
        end
    end
    content_type :json
    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

#
# User
#

get '/user' do
    if request.env["HTTP_ACCEPT"] && request.env["HTTP_ACCEPT"].split(',').grep(/text\/html/).empty?
        user_collection = AppMarket::UserCollection.new(@session)
        @tmp_response = user_collection.info

        status @tmp_response[0]
        body Parser.generate_body({
                'sEcho' => "1",
                'users' => @tmp_response[1]})
    else
        haml :user_index
    end
end

get '/user/:id' do
    @user = AppMarket::UserCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(@user)
        error @user
    end

    if request.env["HTTP_ACCEPT"] && request.env["HTTP_ACCEPT"].split(',').grep(/text\/html/).empty?
        Parser.generate_body(@user.to_hash)
    else
        haml :user_show
    end
end

post '/user/:id/enable' do
    user = AppMarket::UserCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(user)
        error user
    else
        user.enable
    end

    #if update_result != true
    #    status 404
    #end

    if settings.config['mail']
        Mailer.send_enable(user['email'], user['username'])
    end
end

post '/user' do
    begin
        @tmp_response = AppMarket::UserCollection.create(@session, Parser.parse_body(request))
    rescue JSON::ParserError
        error $!.message
    end

    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

put '/user/:id' do
    user = AppMarket::UserCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(user)
        error user
    else
        begin
            user.update(Parser.parse_body(request))
        rescue JSON::ParserError
            error $!.message
        end
    end
end

delete '/user/:id' do
    user = AppMarket::UserCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(user)
        error user
    else
        user.delete
    end
end

#
# Appliance
#

get '/appliance' do
    if request.env["HTTP_ACCEPT"] && request.env["HTTP_ACCEPT"].split(',').grep(/text\/html/).empty?
        app_collection = AppMarket::AppCollection.new(@session)
        @tmp_response = app_collection.info

        status @tmp_response[0]
        body Parser.generate_body({
                'sEcho' => "1",
                'appliances' => @tmp_response[1]})
    else
        haml :appliance_index
    end
end

get '/appliance/:id' do
    app = AppMarket::AppCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(app)
        error app
    end

    @app = app.to_hash

    request_path   = request.env['REQUEST_PATH']
    request_path ||= request.env['REQUEST_URI']
    request_path ||= ''

    appliance_url = (request.env['rack.url_scheme']||'') +
                    '://' +
                    (request.env['HTTP_HOST']||'') +
                    request_path

    @app['links'] = {
        'download' => {
            'href' => appliance_url + '/download'
        }
    }

    if request.env["HTTP_ACCEPT"] && request.env["HTTP_ACCEPT"].split(',').grep(/text\/html/).empty?
        status 200
        body Parser.generate_body(@app)
    else
        render = Redcarpet::Render::HTML.new(
            :filter_html => true,
            :no_images => false,
            :no_links => false,
            :no_styles => true,
            :safe_links_only => true,
            :with_toc_data => true,
            :hard_wrap => true,
            :xhtml => true)

        @markdown = Redcarpet::Markdown.new(render,
            :autolink => true,
            :space_after_headers => true)

        haml :appliance_show
    end
end

post '/appliance' do
    begin
        @tmp_response = AppMarket::AppCollection.create(
                            @session,
                            Parser.parse_body(request))
    rescue JSON::ParserError
        error $!.message
    end

    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

post '/appliance/:id/clone' do
    begin
        @tmp_response = AppMarket::AppCollection.clone(
                            @session,
                            params[:id],
                            Parser.parse_body(request))
    rescue JSON::ParserError
        error $!.message
    end
    status @tmp_response[0]
    body Parser.generate_body(@tmp_response[1])
end

delete '/appliance/:id' do
    app = AppMarket::AppCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(app)
        error app
    else
        app.delete
    end
end

put '/appliance/:id' do
    app = AppMarket::AppCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(app)
        error app
    else
        begin
            @tmp_response = app.update(Parser.parse_body(request))
        rescue JSON::ParserError
            error $!.message
        end

        content_type :json
        status @tmp_response[0]
        body Parser.generate_body(@tmp_response[1])
    end
end

get '/appliance/:id/download' do
    app = AppMarket::AppCollection.get(@session, params[:id], false)
    if AppMarket::Collection.is_error?(app)
        error app
    else
        file_id = params[:file_id]

        if (size = app.file_size(params[:file_id]))
            headers["OpenNebula-AppMarket-Size"] = size
        end

        redirect app.file_url
    end
end

get '/appliance/:id/download/:file_id' do
    app = AppMarket::AppCollection.get(@session, params[:id], false)
    if AppMarket::Collection.is_error?(app)
        error app
    else
        file_id = params[:file_id]

        if (size = app.file_size(params[:file_id]))
            headers["OpenNebula-AppMarket-Size"] = size
        end

        redirect app.file_url(params[:file_id])
    end
end
