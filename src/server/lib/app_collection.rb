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

require 'lib/collection'
require 'lib/app_collection/app'

module AppConverter

    class AppCollection < PoolCollection
        COLLECTION_NAME = "appliance"

        # Create a new collection, the information is not retrieved untill the
        #   the info method is called
        #
        # @param [Hash] selector a document specifying elements which must
        #   be present for a document to be included in the result set.
        # @param [Hash] opts a customizable set of options.
        #   http://api.mongodb.org/ruby/current/Mongo/Collection.html#find-instance_method
        def initialize(selector={}, opts={})
            super(selector, opts)
            @selector = selector
            @opts = opts
        end

        # Retrieve the pool information form the database. The @selector
        #   and @opts will be used to filter the information
        #
        # @return [Integer, Array] status code and array with the resources
        def info
            @data = AppCollection.collection.find(@selector, @opts).to_a

            return [200, self.to_a]
        end

        # Create a new appliance
        #
        # @param [Hash] hash containing the values of the resource
        # @return [Integer, Hash] status code and hash containing the error
        #   message or the info of the resource
        def self.create(hash)
            validator = Validator::Validator.new(
                :default_values => true,
                :delete_extra_properties => false
            )

            begin
                validator.validate!(hash, AppConverter::Appliance::SCHEMA)
            rescue Validator::ParseException
                return [400, {"message" => $!.message}]
            end

            hash['creation_time'] = Time.now.to_i

            begin
                object_id = collection.insert(hash, {:w => 1})
            rescue Mongo::OperationFailure
                return [400, {"message" => "already exists"}]
            end

            app = AppCollection.get(object_id.to_s)

            # Create a new Job to upload the new appliance
            job_hash = {
                'name' => 'upload',
                'appliance_id' => app.object_id
            }

            AppConverter::JobCollection.create(job_hash)

            return [201, app.to_hash]
        end

        # Retrieve the resource from the database. This method must be use
        #   to retrieve the resource instead of Appliance.new
        #
        # @param [String] object_id id of the resource
        # @return [AppConverter::Appliance] depends on the factory method
        def self.get(object_id)
            begin
                data = collection.find_one(
                    :_id => Collection.str_to_object_id(object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if data.nil?
                return [404, {"message" => "Appliance not found"}]
            end

            return self.factory(data)
        end

        protected

        # Default Factory Method for the Pools
        def self.factory(pelem)
            Appliance.new(pelem)
        end

        def factory(pelem)
            AppCollection.factory(pelem)
        end
    end
end

