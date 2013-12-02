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

module AppConverter

    class AppCollection < PoolCollection
        COLLECTION_NAME = "appliance"

        def initialize(filter = {})
            super()
            @filter = filter
        end

        def info
            @data = AppCollection.collection.find(@filter, :fields => nil).to_a

            return [200, @data]
        end

        def self.create(hash)
            validator = Validator::Validator.new(
                :default_values => true,
                :delete_extra_properties => false
            )

            begin
                validator.validate!(hash, AppConverter::Appliance::SCHEMA)
                object_id = collection.insert(hash, {:w => 1})
            rescue Validator::ParseException
                return [400, {"message" => $!.message}]
            rescue Mongo::OperationFailure
                return [400, {"message" => "already exists"}]
            end

            # Create a new Job to upload the new appliance
            job_hash = {
                'name' => 'upload',
                'appliance_id' => object_id.to_s
            }

            AppConverter::JobCollection.create(job_hash)

            app = Appliance.new(object_id.to_s)
            return [201, app.to_hash]
        end

        # Default Factory Method for the Pools
        def factory(pelem)
            AppConverter::Appliance.new(pelem["_id"].to_s)
        end
    end

    class Appliance < Collection
        SCHEMA = {
            :type => :object,
            :properties => {
                'name' => {
                    :type => :string,
                    :required => true
                }
            }
        }

        def initialize(app_id)
            @object_id = app_id
            @data = {"_id" => {"$oid" => app_id}}
        end

        def delete
            begin
                # Remove associated jobs
                job_collection = AppConverter::JobCollection.new(
                    )

                job_collection.info
                job_collection.each { |job|
                    job.cancel
                }

                AppCollection.collection.remove(
                    :_id => Collection.str_to_object_id(@object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            # TODO return code
            return [200, {}]
        end

        def info
            begin
                @data = AppCollection.collection.find_one(
                            :_id => Collection.str_to_object_id(@object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if @data.nil?
                return [404, {"message" => "Appliance not found"}]
            end

            return [200, @data]
        end

        def to_hash
            return @data
        end
    end
end

