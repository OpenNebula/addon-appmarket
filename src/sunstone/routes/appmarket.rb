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


APPMARKET_CONF_FILE = ETC_LOCATION + "/sunstone-appmarket.conf"

$: << RUBY_LIB_LOCATION+"/oneapps/market"

require 'appmarket_client'

begin
    appmarket_conf = YAML.load_file(APPMARKET_CONF_FILE)
rescue Exception => e
    STDERR.puts "Error parsing config file #{APPMARKET_CONF_FILE}: #{e.message}"
    exit 1
end

set :appmarket_config, appmarket_conf

helpers do
    def appmarket_call(&block)
        client  = $cloud_auth.client(session[:user])
        user_id = OpenNebula::User::SELF
        user    = OpenNebula::User.new_with_id(user_id, client)
        rc = user.info
        if OpenNebula.is_error?(rc)
            logger.error { rc.message }
            return [500, ""]
        end

        username = user['TEMPLATE/APPMARKET_USER'] || settings.appmarket_config[:appmarket_username]
        pass = user['TEMPLATE/APPMARKET_PASSWORD'] || settings.appmarket_config[:appmarket_password]

        appmarket_client = AppMarket::Client.new(
            username,
            pass,
            settings.appmarket_config[:appmarket_url],
            "Sunstone")

        resp = block.call(appmarket_client)

        if AppMarket::is_error?(resp)
            begin
                body Error.new(resp.to_s).to_json
            rescue JSON::ParserError
                body resp.to_s
            end
        else
            body resp.body
        end

        http_code = resp.code.to_i
        if http_code == 401
            status 403
        else
            status http_code
        end
    end
end

get '/appmarket/appliance' do
    appmarket_call { |client| client.get_appliances }
end

get '/appmarket/appliance/:id' do
    appmarket_call { |client| client.get_appliance(params[:id]) }
end

post '/appmarket/appliance' do
    appmarket_call { |client| client.create_appliance(request.body.read) }
end

put '/appmarket/appliance/:id' do
    appmarket_call { |client| client.update_appliance(params[:id], request.body.read) }
end

delete '/appmarket/appliance/:id' do
    appmarket_call { |client| client.delete_appliance(params[:id]) }
end

delete '/appmarket/job/:id' do
    appmarket_call { |client| client.delete_job(params[:id]) }
end
