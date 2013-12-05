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

        def initialize(selector={}, opts={})
            super(selector, opts)
            @selector = selector
            @opts = opts
        end

        def info
            @data = AppCollection.collection.find(@selector, @opts).to_a

            return [200, self.to_a]
        end

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

        # Default Factory Method for the Pools
        def self.factory(pelem)
            Appliance.new(pelem)
        end

        def factory(pelem)
            AppCollection.factory(pelem)
        end
    end

    class Appliance < Collection
        STATUS = %w{init ready converting downloading publishing}

        SCHEMA = {
            :type => :object,
            :properties => {
                'name' => {
                    :type => :string,
                    :required => true
                },
                'status' => {
                    :type => :string,
                    :default => 'init',
                    :enum => AppConverter::Appliance::STATUS,
                },
            }
        }

        def initialize(data)
            @data = data
        end

        def delete
            begin
                # Remove associated jobs
                job_selector = {
                    'appliance_id' => self.object_id
                }

                job_collection = AppConverter::JobCollection.new(job_selector)
                job_collection.info
                job_collection.each { |job|
                    job.cancel
                }

                # TODO Keep app until all the jobs are cancelled?
                AppCollection.collection.remove(
                    :_id => Collection.str_to_object_id(self.object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            # TODO return code
            return [200, {}]
        end

        def info
            begin
                @data = AppCollection.collection.find_one(
                            :_id => Collection.str_to_object_id(self.object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if @data.nil?
                return [404, {"message" => "Appliance not found"}]
            end

            return [200, self.to_hash]
        end

        def update(opts)
            # TODO check opts keys
            @data = @data.deep_merge(opts)
            AppCollection.collection.update(
                    {:_id => Collection.str_to_object_id(self.object_id)},
                    @data)

            # TODO check if update == success

            return [200, {}]
        end
    end
end

