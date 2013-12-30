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
        appmarket_client = AppMarket::Client.new(
            settings.appmarket_config[:appmarket_username],
            settings.appmarket_config[:appmarket_password],
            settings.appmarket_config[:appmarket_url],
            "Sunstone")

        resp = block.call(appmarket_client)

        if CloudClient::is_error?(resp)
            body Error.new(JSON.parse(resp.to_s)['message']).to_json
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

get '/appmarket/job' do
    appmarket_call { |client| client.get_jobs }
end

get '/appmarket/job/:id' do
    appmarket_call { |client| client.get_job(params[:id]) }
end

post '/appmarket/job' do
    appmarket_call { |client| client.create_job(request.body.read) }
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
