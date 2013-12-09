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
require 'net/https'

module AppConverter
    module CloudClient
        # #########################################################################
        # Starts an http connection and calls the block provided. SSL flag
        # is set if needed.
        # #########################################################################
        def self.http_start(url, timeout, &block)
            host = nil
            port = nil

            if ENV['http_proxy']
                uri_proxy  = URI.parse(ENV['http_proxy'])
                host = uri_proxy.host
                port = uri_proxy.port
            end

            http = Net::HTTP::Proxy(host, port).new(url.host, url.port)

            if timeout
                http.read_timeout = timeout.to_i
            end

            if url.scheme=='https'
                http.use_ssl = true
                http.verify_mode=OpenSSL::SSL::VERIFY_NONE
            end

            begin
                res = http.start do |connection|
                    block.call(connection)
                end
            rescue Errno::ECONNREFUSED => e
                str =  "Error connecting to server (#{e.to_s}).\n"
                str << "Server: #{url.host}:#{url.port}"

                return CloudClient::Error.new(str,"503")
            rescue Errno::ETIMEDOUT => e
                str =  "Error timeout connecting to server (#{e.to_s}).\n"
                str << "Server: #{url.host}:#{url.port}"

                return CloudClient::Error.new(str,"504")
            rescue Timeout::Error => e
                str =  "Error timeout while connected to server (#{e.to_s}).\n"
                str << "Server: #{url.host}:#{url.port}"

                return CloudClient::Error.new(str,"504")
            rescue SocketError => e
                str =  "Error timeout while connected to server (#{e.to_s}).\n"

                return CloudClient::Error.new(str,"503")
            rescue
                return CloudClient::Error.new($!.to_s,"503")
            end

            if res.is_a?(Net::HTTPSuccess)
                res
            else
                CloudClient::Error.new(res.body, res.code)
            end
        end

        # #########################################################################
        # The Error Class represents a generic error in the Cloud Client
        # library. It contains a readable representation of the error.
        # #########################################################################
        class Error
            attr_reader :message
            attr_reader :code

            # +message+ a description of the error
            def initialize(message=nil, code="500")
                @message=message
                @code=code
            end

            def to_s()
                @message
            end
        end

        # #########################################################################
        # Returns true if the object returned by a method of the OpenNebula
        # library is an Error
        # #########################################################################
        def self.is_error?(value)
            value.class==CloudClient::Error
        end
    end

    class Client
        VERSION = "0.8.0"

        def initialize(username=nil, password=nil, url=nil, user_agent="Ruby")
            #@username = username || ENV['APPCONVERTER_USER']
            #@password = password || ENV['APPCONVERTER_PASSWORD']

            url = url || ENV['APPCONVERTER_URL'] || 'http://localhost:6243/'
            @uri = URI.parse(url)

            @user_agent = "AppConverter #{AppConverter::Client::VERSION} (#{user_agent})"

            @host = nil
            @port = nil

            if ENV['http_proxy']
                uri_proxy  = URI.parse(ENV['http_proxy'])
                @host = uri_proxy.host
                @port = uri_proxy.port
            end
        end

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

        private

        def do_request(req)
            #if @username && @password
            #    req.basic_auth @username, @password
            #end

            req['User-Agent'] = @user_agent

            res = CloudClient::http_start(@uri, @timeout) do |http|
                http.request(req)
            end

            res
        end
    end
end
