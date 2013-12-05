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
            super(selector, opts)
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
            app = AppConverter::AppCollection.get(hash['appliance_id'])
            if Collection.is_error?(app)
                return app
            end

            hash['creation_time'] = Time.now.to_i

            begin
                object_id = collection.insert(hash)
            rescue Mongo::OperationFailure
                return [400, {"message" => "already exists"}]
            end

            job = JobCollection.get(object_id.to_s)
            return [201, job.to_hash]
        end

        def self.get(object_id)
            begin
                data = collection.find_one(
                    :_id => Collection.str_to_object_id(object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if data.nil?
                return [404, {"message" => "Job not found"}]
            end

            return self.factory(data)
        end

        # Default Factory Method for the Pools
        def self.factory(pelem)
            case pelem['name']
            when 'upload'
                return UploadJob.new(pelem)
            when 'convert'
                return ConvertJob.new(pelem)
            end
        end

        def factory(pelem)
            JobCollection.factory(pelem)
        end
    end

    class Job < Collection
        # Callbacks that can be sent from the worker to a given job to update
        #   its state
        CALLBACKS = %{done error update cancel}

        STATUS  = %w{pending in-progress cancelling done error cancelled}
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

        def initialize(data)
            @data = data
        end

        # Cancel the job. If the job is in a worker node (worker_host!=nil)
        #   the job is tagged to be canceled by the worker, otherwise the
        #   state of the job is set to deleted
        #
        # @return [Integer, Hash] status code and hash with the info
        def cancel
            begin
                if @data['worker_host'].nil?
                    status = 'cancelled'
                else
                    status = 'cancelling'
                end

                JobCollection.collection.update({
                    :_id => Collection.str_to_object_id(self.object_id)},
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
                    :_id => Collection.str_to_object_id(self.object_id))
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
                    :_id => Collection.str_to_object_id(self.object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if @data.nil?
                return [404, {"message" => "Job not found"}]
            end

            return [200, self.to_hash]
        end

        def update(job_hash)
            @data = @data.deep_merge(job_hash)
            JobCollection.collection.update(
                    {:_id => Collection.str_to_object_id(self.object_id)},
                    @data)

            # TODO check if update == success

            return [200, {}]
        end

        def update_from_callback(job_hash_update, app_hash_update={})
            if !app_hash_update.empty?
                app = AppConverter::AppCollection.get(@data['appliance_id'])
                if !Collection.is_error?(app)
                    app_update_result = app.update(app_hash_update)
                    if Collection.is_error?(app_update_result)
                        return app_update_result
                    end
                end
            end

            # TODO check worker_host matches

            self.update(job_hash_update)
        end

        def start(job_hash, app_hash={})
            job_hash_update = {
                'status' => 'in-progress',
                'start_time' => Time.now.to_i
            }.deep_merge(job_hash)

            app_hash_update = {}.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end

        def cb_done(job_hash, app_hash={})
            job_hash_update = {
                'status' => 'done',
                'end_time' => Time.now.to_i
            }.deep_merge(job_hash)

            app_hash_update = {
                'status' => 'ready'
            }.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end

        def cb_error(job_hash, app_hash={})
            job_hash_update = {
                'status' => 'error',
                'end_time' => Time.now.to_i
            }.deep_merge(job_hash)

            app_hash_update = {
                'status' => 'ready'
            }.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end

        def cb_cancel(job_hash, app_hash={})
            job_hash_update = {
                'status' => 'cancelled',
                'end_time' => Time.now.to_i
            }.deep_merge(job_hash)

            app_hash_update = {
                'status' => 'ready'
            }.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end
    end

    class UploadJob < Job
        def initialize(data)
            super(data)
        end

        def start(worker_host)
            job_hash = {
                'worker_host' => worker_host
            }

            app_hash = {
                'status' => 'downloading'
            }

            super(job_hash, app_hash)
        end

        def cb_done(worker_host)
            job_hash = {}
            app_hash = {}

            super(job_hash, app_hash)
        end

        def cb_error(worker_host)
            job_hash = {}
            app_hash = {}

            super(job_hash, app_hash)
        end

        def cb_cancel(worker_host)
            job_hash = {}
            app_hash = {}

            super(job_hash, app_hash)
        end
    end

    class ConvertJob < Job
        def initialize(data)
            super(data)
        end

        def start(worker_host)
            job_hash = {
                'worker_host' => worker_host
            }

            app_hash = {
                'status' => 'converting'
            }

            super(job_hash, app_hash)
        end

        def cb_done(worker_host)
            job_hash = {}
            app_hash = {}

            super(job_hash, app_hash)
        end

        def cb_error(worker_host)
            job_hash = {}
            app_hash = {}

            super(job_hash, app_hash)
        end

        def cb_cancel(worker_host)
            job_hash = {}
            app_hash = {}

            super(job_hash, app_hash)
        end
    end
end
