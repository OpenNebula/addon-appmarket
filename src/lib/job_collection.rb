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

        def initialize(selector={}, opts={})
            super()
            @selector = selector
            @opts = opts
        end

        def info
            @data = JobCollection.collection.find(@selector, @opts).to_a

            return [200, self.to_a]
        end

        def self.create(hash)
            validator = Validator::Validator.new(
                :default_values => true,
                :delete_extra_properties => false
            )

            begin
                validator.validate!(hash, AppConverter::Job::SCHEMA)
            rescue Validator::ParseException
                return [400, {"message" => $!.message}]
            end

            # Check if the app exists
            result = AppConverter::Appliance.new(hash['appliance_id']).info
            if Collection.is_error?(result)
                return result
            end

            hash['creation_time'] = Time.now.to_i

            begin
                object_id = collection.insert(hash, {:w => 1})
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
        STATUS  = %w{pending in-progress cancelling done error deleted}
        NAMES   = %w{upload delete convert publish unpublish}
        # TODO define formats
        FORMATS = %w{qcow vmdk}

        SCHEMA = {
            :type => :object,
            :properties => {
                'name' => {
                    :type => :string,
                    :required => true,
                    :enum => AppConverter::Job::NAMES,
                },
                'status' => {
                    :type => :string,
                    :default => 'pending',
                    :enum => AppConverter::Job::STATUS,
                },
                'appliance_id' => {
                    :type => :string,
                    :required => true
                },
                'creation_time' => {
                    :type => :null
                },
                'start_time' => {
                    :type => :null
                },
                'completition_time' => {
                    :type => :null
                },
                'information' => {
                    :type => :null
                },
                'worker_host' => {
                    :type => :null
                },
                'worker_pid' => {
                    :type => :null
                },
                'params' => {
                    :type => :object,
                    :properties => {
                        # TODO define parameters
                        'url' => {
                            :type => :uri
                        },
                        'formats' => {
                            :type => :array,
                            :items => {
                                :type => :string,
                                :enum => AppConverter::Job::FORMATS
                            }
                        }
                    }
                }
            }
        }

        def initialize(job_id)
            @object_id = job_id
            @data = {}
        end

        # Cancel the job. If the job is in a worker node (worker_host!=nil)
        #   the job is tagged to be canceled by the worker, otherwise the
        #   state of the job is set to deleted
        #
        # @return [Integer, Hash] status code and hash with the info
        def cancel
            begin
                job = self.info
                if Collection.is_error?(job)
                    return job
                end

                if @data['worker_host'].nil?
                    status = 'deleted'
                else
                    status = 'cancelling'
                end

                JobCollection.collection.update({
                    :_id => Collection.str_to_object_id(@object_id)},
                    {'$set' => {"status" => status}
                })
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            # TODO return code
            return [202, {}]
        end

        def delete
            begin
                JobCollection.collection.remove(
                    :_id => Collection.str_to_object_id(@object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            # TODO return code
            return [200, {}]
        end

        # Query the database to retrieve the information of the Job
        #
        # @return [Integer, Hash] status code and hash with the info
        def info
            begin
                @data = JobCollection.collection.find_one(
                    :_id => Collection.str_to_object_id(@object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if @data.nil?
                return [404, {"message" => "Job not found"}]
            end

            return [200, self.to_hash]
        end

        def update(opts)
            # TODO check opts keys
            if @data.empty?
                info_result = self.info
                if Collection.is_error?(info_result)
                    return info_result
                end
            end

            app = AppConverter::Appliance.new(@data['appliance_id'])
            app_hash_update = {}
            case opts['status']
            when 'in-progress'
                case @data['name']
                when 'upload'
                    app_hash_update['status'] = 'downloading'
                end
            end

            app_update_result = app.update(app_hash_update)
            if Collection.is_error?(app_update_result)
                return app_update_result
            end

            @data = @data.deep_merge(opts)
            JobCollection.collection.update(
                    {:_id => Collection.str_to_object_id(@object_id)},
                    @data)

            # TODO check if update == success

            return [200, {}]
        end
    end
end
