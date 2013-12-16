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

        # This method should be used only by the factory method, to retrieve
        #   an existing resource from the database use the AppCollecion.get
        #   method
        def initialize(data)
            @data = data
        end

        # Delete the appliance from the database and cancel the associated
        #   jobs of the appliance.
        #
        # @return [Integer, Hash] status code and hash with the error message
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

        # Query the database to retrieve the information of the appliance
        #
        # @return [Integer, Hash] status code and hash with the info
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

        # Update the appliance
        #
        # @param [Hash] opts Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information
        # @return [Integer, Hash] status code and hash with the error message
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
