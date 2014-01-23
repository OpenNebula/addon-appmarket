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
require 'mongo'
require 'yaml'

module AppMarket
    VERSION = "1.8.0"
    VERSION_CODE = 10800

    DB_NAME = ENV['APPMARKET_DB'] || 'market'

    CONFIGURATION_FILE = ETC_LOCATION + "/appmarket-server.conf"

    begin
        CONF = YAML.load_file(CONFIGURATION_FILE)
    rescue Exception => e
        STDERR.puts "Error parsing config file #{CONFIGURATION_FILE}: #{e.message}"
        exit 1
    end

    DB = Mongo::Connection.new(CONF['db_host'], CONF['db_port']).db(DB_NAME)

    module DBVersioning
        DB_VERSIONING_COLLECTION = 'db_versioning'

        def self.insert_db_version(version, version_code)
            AppMarket::DB[DB_VERSIONING_COLLECTION].insert({
                'version' => version,
                'version_code' => version_code,
                'timestamp' => Time.now.to_i})
        end

        def self.get_version_codes
            versions = AppMarket::DB[DB_VERSIONING_COLLECTION].find(
                {},{:fields => {"_id" => 0, "version_code" => 1}}).to_a

            versions.collect {|version| version['version_code']}
        end
    end
end
