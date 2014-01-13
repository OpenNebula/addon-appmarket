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

require 'uri'
require 'CloudClient'

module AppMarket
    class Client
        def initialize(username, password, url, user_agent="Ruby")
            @username = username || ENV['APPMARKET_USER']
            @password = password || ENV['APPMARKET_PASSWORD']

            url = url || ENV['APPMARKET_URL'] || 'http://localhost:6242/'
            @uri = URI.parse(url)

            @user_agent = "OpenNebula #{CloudClient::VERSION} (#{user_agent})"

            @host = nil
            @port = nil

            if ENV['http_proxy']
                uri_proxy  = URI.parse(ENV['http_proxy'])
                @host = uri_proxy.host
                @port = uri_proxy.port
            end
        end

        def create_job(body)
            post('/job', body)
        end

        def get_jobs(filter={})
            str = filter.collect {|key, value|
                key + '=' + value
            }.join('&')

            path = '/job'
            path += '?' + str if str
            get(path)
        end

        def get_job(job_id)
            get('/job/' + job_id)
        end

        def delete_job(job_id)
            delete('/job/' + job_id)
        end

        def get_next_job(worker_id)
            get('/worker/' + worker_id + '/nextjob')
        end

        def get_worker_jobs(worker_id, filter={})
            str = filter.collect {|key, value|
                key + '=' + value
            }.join('&')

            path = '/worker/'
            path << worker_id
            path << '/job'

            if str
                path << '?' + str
            end

            get(path)
        end

        def callback_url(worker_id, job_id)
            return @uri.to_s + 'worker/' + worker_id + '/job/' + job_id
        end

        def create_appliance(body)
            post('/appliance', body)
        end

        def get_appliances
            get('/appliance')
        end

        def get_appliance(appliance_id)
            get('/appliance/' + appliance_id)
        end

        def delete_appliance(appliance_id)
            delete('/appliance/' + appliance_id)
        end

        def update_appliance(appliance_id, body)
            put('/appliance/' + appliance_id, body)
        end

        def convert_appliance(appliance_id, body)
            post('/appliance/' + appliance_id + '/clone', body)
        end

        def callback(url, result, json_body="")
            uri = URI.parse(url)

            # TODO Check result is a valid callback
            post(uri.path + '/' + result, json_body)
        end

        def create_user(body)
            post('/user', body)
        end

        def get_users
            get('/user')
        end

        def get_user(user_id)
            get('/user/' + user_id)
        end

        def enable_user(user_id)
            post("/user/#{user_id}/enable", "")
        end

        def update_user(user_id, body)
            put('/user/' + user_id, body)
        end

        def delete_user(user_id)
            delete('/user/' + user_id)
        end

        private

        def get(path)
            req = Net::HTTP::Proxy(@host, @port)::Get.new(path)

            do_request(req)
        end

        def delete(path)
            req = Net::HTTP::Proxy(@host, @port)::Delete.new(path)

            do_request(req)
        end

        def post(path, body)
            req = Net::HTTP::Proxy(@host, @port)::Post.new(path)
            req.body = body

            do_request(req)
        end

        def put(path, body)
            req = Net::HTTP::Proxy(@host, @port)::Put.new(path)
            req.body = body

            do_request(req)
        end

        def do_request(req)
            if @username && @password
                req.basic_auth @username, @password
            end

            req['User-Agent'] = @user_agent

            res = CloudClient::http_start(@uri, @timeout) do |http|
                http.request(req)
            end

            res
        end
    end
end
