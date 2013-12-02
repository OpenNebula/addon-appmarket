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

    class JobCollection < PoolCollection
        COLLECTION_NAME = "jobs"

        def initialize(filter = {})
            super()
            @filter = filter
        end

        def info
            @data = JobCollection.collection.find(@filter, :fields => nil).to_a

            return [200, @data]
        end

        def self.create(hash)
            validator = Validator::Validator.new(
                :default_values => true,
                :delete_extra_properties => false
            )

            begin
                validator.validate!(hash, AppConverter::Job::SCHEMA)

                # TODO check if the app exists

                object_id = collection.insert(hash, {:w => 1})
            rescue Validator::ParseException
                return [400, {"message" => $!.message}]
            rescue Mongo::OperationFailure
                return [400, {"message" => "already exists"}]
            end

            job = Job.new(object_id.to_s)
            return [201, job.to_hash]
        end

        # Default Factory Method for the Pools
        def factory(pelem)
            AppConverter::Job.new(pelem["_id"].to_s)
        end
    end

    class Job < Collection
        COLLECTION_NAME = "jobs"

        SCHEMA = {
            :type => :object,
            :properties => {
                'name' => {
                    :type => :string,
                    :required => true,
                    :enum => %w{upload delete convert publish unpublish},
                },
                'status' => {
                    :type => :string,
                    :default => 'pending',
                    :enum => %w{pending in-progress cancel done error deleted},
                },
                'appliance_id' => {
                    :type => :string,
                    :required => true
                }
            }
        }

        def initialize(job_id)
            @object_id = job_id
            @data = {"_id" => {"$oid" => job_id}}
        end

        def cancel
            begin
                job = Job.collection.update({
                    :_id => Collection.str_to_object_id(@object_id)},
                    {'$set' => {"status" => "cancel"}
                })
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end
        end

        def delete
            begin
                Job.collection.remove(:_id => Collection.str_to_object_id(@object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            # TODO return code
            return [200, {}]
        end

        def info
            begin
                @data = Job.collection.find_one(:_id => Collection.str_to_object_id(@object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if @data.nil?
                return [404, {"message" => "Job not found"}]
            end

            return [200, @data]
        end

        def to_hash
            return @data
        end
    end
end
