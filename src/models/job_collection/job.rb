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

module AppConverter
    class Job < Collection
        # Callbacks that can be sent from the worker to a given job to update
        #   its state
        CALLBACKS = %{done error update cancel}

        STATUS  = %w{pending in-progress cancelling done error cancelled}
        NAMES   = %w{upload delete convert publish unpublish}
        # TODO define formats
        FORMATS = %w{qcow2 vmdk}

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
                'error_message' => {
                    :type => :string
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
                        'from_appliance' => {
                            :type => :string
                        },
                        'from_format' => {
                            :type => :string
                        },
                        'format' => {
                            :type => :string,
                            :enum => AppConverter::Job::FORMATS
                        }
                    }
                }
            }
        }

        # This method should be used only by the factory method, to retrieve
        #   an existing resource from the database use the JobCollection.get
        #   method
        def initialize(session, data)
            @session = session
            @data = data
        end

        # Cancel the job. If the job is in a worker node (worker_host!=nil)
        #   the job is tagged to be canceled by the worker, otherwise the
        #   state of the job is set to cancelled
        #
        # @return [Integer, Hash] status code and hash with the error message
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

            return [202, {}]
        end

        # Delete the job from the database
        #
        # @return [Integer, Hash] status code and hash with the error message
        def delete
            # TODO if status == in-progress then error, the job must be cancelled first
            begin
                JobCollection.collection.remove(
                    :_id => Collection.str_to_object_id(self.object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

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

        # Update the job
        #
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information
        # @return [Integer, Hash] status code and hash with the error message
        def update(job_hash)
            @data = @data.deep_merge(job_hash)
            JobCollection.collection.update(
                    {:_id => Collection.str_to_object_id(self.object_id)},
                    @data)

            # TODO check if update == success

            return [200, {}]
        end

        protected

        # Start the job.
        #   This method must be implemented by the subclass. This method
        #   defines the values that all the jobs will set when started
        #   and will be merged with the values provided by the subclass
        #
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def start(job_hash, app_hash={})
            job_hash_update = {
                'status' => 'in-progress',
                'progress' => 0,
                'start_time' => Time.now.to_i
            }.deep_merge(job_hash)

            app_hash_update = {}.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end

        # Done callback from the worker.
        #   This method must be implemented by the subclass. This method
        #   defines the values that all the jobs will set in this callback
        #   and will be merged with the values provided by the subclass
        #
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def cb_done(job_hash, app_hash={})
            job_hash_update = {
                'status' => 'done',
                'progress' => 100,
                'end_time' => Time.now.to_i
            }.deep_merge(job_hash)

            app_hash_update = {
                'status' => 'ready'
            }.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end

        # Error callback from the worker.
        #   This method must be implemented by the subclass. This method
        #   defines the values that all the jobs will set in this callback
        #   and will be merged with the values provided by the subclass
        #
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def cb_error(job_hash, app_hash={})
            job_hash_update = {
                'status' => 'error',
                'end_time' => Time.now.to_i
            }.deep_merge(job_hash)

            app_hash_update = {}.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end

        # Cancel callback from the worker.
        #   This method must be implemented by the subclass. This method
        #   defines the values that all the jobs will set in this callback
        #   and will be merged with the values provided by the subclass
        #
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def cb_cancel(job_hash, app_hash={})
            job_hash_update = {
                'status' => 'cancelled',
                'end_time' => Time.now.to_i
            }.deep_merge(job_hash)

            app_hash_update = {}.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end

        # Update callback from the worker.
        #   This method must be implemented by the subclass. This method
        #   defines the values that all the jobs will set in this callback
        #   and will be merged with the values provided by the subclass
        #
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def cb_update(job_hash, app_hash={})
            job_hash_update = {}.deep_merge(job_hash)
            app_hash_update = {}.deep_merge(app_hash)

            self.update_from_callback(job_hash_update, app_hash_update)
        end

        # Update the information of the job and the appliance with the values
        #   provided by the callbacks
        #
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def update_from_callback(job_hash_update, app_hash_update={})
            if !app_hash_update.empty?
                app = AppConverter::AppCollection.get(@session, @data['appliance_id'])
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
    end
end
