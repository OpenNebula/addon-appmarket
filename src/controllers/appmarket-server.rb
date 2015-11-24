#------------------------------------------------------------------------------#
# Copyright 2002-2015, OpenNebula Project, OpenNebula Systems                  #
#                                                                              #
# Licensed under the Apache License, Version 2.0 (the "License"); you may      #
# not use this file except in compliance with the License. You may obtain      #
# a copy of the License at                                                     #
#                                                                              #
# http://www.apache.org/licenses/LICENSE-2.0                                   #
#                                                                              #
# Unless required by applicable law or agreed to in writing, software          #
# distributed under the License is distributed on an "AS IS" BASIS,            #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.     #
# See the License for the specific language governing permissions and          #
# limitations under the License.                                               #
#------------------------------------------------------------------------------#

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
    set :public_folder, File.join(File.dirname(__FILE__), '..', 'public')
    set :public, File.join(File.dirname(__FILE__), '..', 'public')

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

delete '/appliance/:id' do
    app = AppMarket::AppCollection.get(@session, params[:id])
    if AppMarket::Collection.is_error?(app)
        error app
    else
        app.delete
        status 204
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
