#------------------------------------------------------------------------------#
# Copyright 2002-2014, OpenNebula Project (OpenNebula.org), OpenNebula Systems #
#                                                                              #
# Licensed under the Apache License, Version 2.0 (the "License"); you may      #
# not use this file except in compliance with the License. You may obtain      #
# a copy of the License at                                                     #
#                                                                              #
# http://www.apache.org/licenses/LICENSE-2.0                                   #
#                                                                              #
# Unless required by applicable law or agreed to in writing, software          #
# distributed under the License is distributed on an "AS IS" BASIS,            #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.     #
# See the License for the specific language governing permissions and          #
# limitations under the License.                                               #
#------------------------------------------------------------------------------#

module AppMarket

    class JobCollection < PoolCollection
        COLLECTION_NAME = "jobs"

        # Create a new collection, the information is not retrieved untill the
        #   the info method is called
        #
        # @param [Hash] selector a document specifying elements which must
        #   be present for a document to be included in the result set.
        # @param [Hash] opts a customizable set of options.
        #   http://api.mongodb.org/ruby/current/Mongo/Collection.html#find-instance_method
        def initialize(session, selector={}, opts={})
            super(session, selector, opts)
            @selector = selector
            @opts = opts
        end

        # Retrieve the pool information form the database. The @selector
        #   and @opts will be used to filter the information
        #
        # @return [Integer, Array] status code and array with the resources
        def info
            @data = JobCollection.collection.find(@selector, @opts).to_a

            return [200, self.to_a]
        end

        # Create a new Job
        #
        # @param [Hash] hash containing the values of the resource
        # @return [Integer, Hash] status code and hash containing the error
        #   message or the info of the resource
        def self.create(session, hash)
            validator = Validator::Validator.new(
                :default_values => true,
                :delete_extra_properties => true
            )

            begin
                validator.validate!(hash, AppMarket::Job::SCHEMA)
            rescue Validator::ParseException
                return [400, {"message" => $!.message}]
            end

            # Check if the app exists
            app = AppMarket::AppCollection.get(session, hash['appliance_id'])
            if Collection.is_error?(app)
                return app
            end

            hash['appliance'] = app.to_hash
            hash['creation_time'] = Time.now.to_i

            begin
                mongo_object_id = collection.insert(hash)
            rescue Mongo::OperationFailure
                return [400, {"message" => "already exists"}]
            end

            job = JobCollection.get(session, mongo_object_id.to_s)
            return [201, job.to_hash]
        end

        # Retrieve the resource from the database. This method must be use
        #   to retrieve the resource instead of Job.new
        #
        # @param [String] mongo_object_id id of the resource
        # @return [AppMarket::Job] depends on the factory method
        def self.get(session, mongo_object_id)
            begin
                data = collection.find_one(
                    :_id => Collection.str_to_mongo_object_id(mongo_object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if data.nil?
                return [404, {"message" => "Job not found"}]
            end

            return self.factory(session, data)
        end

        protected

        # Default Factory Method for the Pools
        def self.factory(session, pelem)
            case pelem['name']
            when 'upload'
                return UploadJob.new(session, pelem)
            when 'convert'
                return ConvertJob.new(session, pelem)
            when 'delete'
                return DeleteJob.new(session, pelem)
            end
        end

        def factory(session, pelem)
            JobCollection.factory(session, pelem)
        end
    end
end
