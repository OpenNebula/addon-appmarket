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
    def am_build_client
        AppConverter::Client.new(
            settings.appconverter_config[:appconverter_url],
            "Sunstone")
    end

    def am_format_response(response)
        if CloudClient::is_error?(response)
            error = Error.new(response.to_s)
            [response.code.to_i, error.to_json]
        else
            [200, response.body]
        end
    end
end

get '/appconverter/job' do
    client = am_build_client

    response = client.get_jobs

    am_format_response(response)
end

get '/appconverter/job/:id' do
    client = am_build_client

    response = client.get_job(params[:id])

    am_format_response(response)
end

post '/appconverter/job' do
    client = af_build_client

    resp = client.create_job(request.body.read)

    af_format_response(resp)
end

get '/appconverter/appliance' do
    client = am_build_client

    response = client.get_appliances

    am_format_response(response)
end

get '/appconverter/appliance/:id' do
    client = am_build_client

    response = client.get_appliance(params[:id])

    am_format_response(response)
end

post '/appconverter/appliance' do
    client = af_build_client

    resp = client.create_appliance(request.body.read)

    af_format_response(resp)
end
