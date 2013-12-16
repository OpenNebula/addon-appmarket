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

    class UploadJob < Job
        # This method should be used only by the factory method, to retrieve
        #   an existing resource from the database use the JobCollection.get
        #   method
        def initialize(data)
            super(data)
        end

        # Start the job
        #   This method defines the specific values that a UploadJob defines
        #   when started The common values are defined in the parent class
        #
        # @param [String] worker_host
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def start(worker_host, job_hash, app_hash)
            job_hash_merged = {
                'worker_host' => worker_host
            }.deep_merge(job_hash)

            app_hash_merged = {
                'status' => 'downloading'
            }.deep_merge(app_hash)

            super(job_hash_merged, app_hash_merged)
        end

        # Done callback
        #   This method defines the specific values that a UploadJob defines
        #   for this callback. The common values are defined in the parent class
        #
        # @param [String] worker_host
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def cb_done(worker_host, job_hash, app_hash)
            job_hash_merged = {}.deep_merge(job_hash||{})
            app_hash_merged = {}.deep_merge(app_hash||{})

            super(job_hash_merged, app_hash_merged)
        end

        # Error callback
        #   This method defines the specific values that a UploadJob defines
        #   for this callback. The common values are defined in the parent class
        #
        # @param [String] worker_host
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def cb_error(worker_host, job_hash, app_hash)
            job_hash_merged = {}.deep_merge(job_hash||{})
            app_hash_merged = {
                'status' => 'init'
            }.deep_merge(app_hash||{})

            super(job_hash_merged, app_hash_merged)
        end

        # Cancel callback
        #   This method defines the specific values that a UploadJob defines
        #   for this callback. The common values are defined in the parent class
        #
        # @param [String] worker_host
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def cb_cancel(worker_host, job_hash, app_hash)
            job_hash_merged = {}.deep_merge(job_hash||{})
            app_hash_merged = {
                'status' => 'init'
            }.deep_merge(app_hash||{})

            super(job_hash_merged, app_hash_merged)
        end

        # Update callback
        #   This method defines the specific values that a UploadJob defines
        #   for this callback. The common values are defined in the parent class
        #
        # @param [String] worker_host
        # @param [Hash] job_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the job
        # @param [Hash] app_hash Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information of the appliance
        # @return [Integer, Hash] status code and hash with the error message
        def cb_update(worker_host, job_hash, app_hash)
            job_hash_merged = {}.deep_merge(job_hash||{})
            app_hash_merged = {}.deep_merge(app_hash||{})

            super(job_hash_merged, app_hash_merged)
        end
    end
end
