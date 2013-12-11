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

APPCONVERTER_CONF_FILE = ETC_LOCATION + "/sunstone-appconverter.conf"

$: << RUBY_LIB_LOCATION + "/appconverter"

require 'appconverter-client'

begin
    appconverter_conf = YAML.load_file(APPCONVERTER_CONF_FILE)
rescue Exception => e
    STDERR.puts "Error parsing config file #{APPCONVERTER_CONF_FILE}: #{e.message}"
    exit 1
end

set :appconverter_config, appconverter_conf


helpers do
    def appconverter_call(&block)
        appconverter_client = AppConverter::Client.new(
            settings.appconverter_config[:appconverter_url],
            "Sunstone")

        resp = block.call(appconverter_client)

        if AppConverter::CloudClient::is_error?(resp)
            body Error.new(JSON.parse(resp.to_s)['message']).to_json
        else
            body resp.body
        end

        status resp.code.to_i
    end
end

get '/appconverter/job' do
    appconverter_call { |client| client.get_jobs }
end

get '/appconverter/job/:id' do
    appconverter_call { |client| client.get_job(params[:id]) }
end

post '/appconverter/job' do
    appconverter_call { |client| client.create_job(request.body.read) }
end

get '/appconverter/appliance' do
    appconverter_call { |client| client.get_appliances }
end

get '/appconverter/appliance/:id' do
    appconverter_call { |client| client.get_appliance(params[:id]) }
end

post '/appconverter/appliance' do
    appconverter_call { |client| client.create_appliance(request.body.read) }
end
