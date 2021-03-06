#------------------------------------------------------------------------------#
# Copyright 2002-2015, OpenNebula Project, OpenNebula Systems                  #
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

    class AppCollection < PoolCollection
        COLLECTION_NAME = "appliances"

        # Create a new collection, the information is not retrieved untill the
        #   the info method is called
        #
        # @param [Session] session an instance of Session containing
        #   the user permisions
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
        # @param [Session] session an instance of Session containing
        #   the user permisions
        # @return [Integer, Array] status code and array with the resources
        def info
            selector = @selector.deep_merge(AppCollection.generate_filter(@session, nil))
            opts = @opts.deep_merge({:fields => AppCollection.exclude_fields(@session)})

            @data = AppCollection.collection.find(selector, opts).to_a

            return [200, self.to_a]
        end

        # Create a new appliance
        #
        # @param [Session] session an instance of Session containing the user permisions
        # @param [Hash] hash containing the values of the resource
        # @return [Integer, Hash] status code and hash containing the error
        #   message or the info of the resource
        def self.create(session, hash)
            validator = Validator::Validator.new(
                :default_values => true,
                :delete_extra_properties => true
            )

            begin
                validator.validate!(hash, session.schema(:appliance))
            rescue Validator::ParseException
                return [400, {"message" => $!.message}]
            end

            hash['creation_time'] = Time.now.to_i
            hash['publisher'] = session.publisher

#        if hash['files'][0]['url']
#            uri = URI.parse(hash['files'][0]['url'])
#
#            begin
#                response = nil
#                Net::HTTP.start(uri.host,uri.port) do |http|
#                    response = http.head(uri.path)
#                end
#
#                hash['files'][0]['size'] = response.content_length
#            rescue
#                raise "The URL is not valid"
#            end
#        end
#

            begin
                mongo_object_id = collection.insert(hash, {:w => 1})
            rescue Mongo::OperationFailure
                return [400, {"message" => "already exists"}]
            end

            app = AppCollection.get(session, mongo_object_id.to_s)

            if hash['files'].nil? || hash['files'][0]['url'].nil?
                return [400, {"message" => "No file url was provided for this app"}]
            else
                app.update({'status' => 'ready'})
            end

            return [201, app.to_hash]
        end

        # Retrieve the resource from the database. This method must be use
        #   to retrieve the resource instead of Appliance.new
        #
        # @param [Session] session an instance of Session containing the
        #   user permisions
        # @param [String] mongo_object_id id of the resource
        # @param [true,false] exclude_fields exclude fields from the appliance
        #   information, the fields are defined in the exclude_fields method
        # @return [AppMarket::Appliance] depends on the factory method
        def self.get(session, mongo_object_id, exclude_fields=true)
            begin
                filter = generate_filter(session, mongo_object_id)
                fields = exclude_fields(session) if exclude_fields
                data = collection.find_one(filter, :fields => fields)
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if data.nil?
                return [404, {"message" => "Appliance not found"}]
            end

            if data['publisher'] == session.publisher
                # if the session user is the owner, retrieve all the metadata
                data = collection.find_one(filter)
            end


            self.factory(session, data)
        end

        protected

        # Default Factory Method for the Pools
        def self.factory(session, pelem)
            Appliance.new(session, pelem)
        end

        def factory(session, pelem)
            AppCollection.factory(session, pelem)
        end

        # Generate a Hash containing the filter to be applied to the query
        #
        # @params [Session] session an instance of Session containing the user permisions
        # @param [String] app_id id of the appliance
        # @return [Hash] a hash containing the contraints
        def self.generate_filter(session, app_id)
            filter = Hash.new

            if session.allowed_catalogs
                filter["catalog"] = {
                    "$in" => session.allowed_catalogs
                }
            end

            if app_id
                filter["_id"] = BSON::ObjectId(app_id)
            end

            filter
        end

        # Generate a Hash containing the fields to be excluded, a key with value
        #   0 will be excluded.
        #
        # @params [Session] session an instance of Session containing the user permisions
        # @return [Hash] a hash of fields
        def self.exclude_fields(session)
            if session.admin?
                nil
            else
                {
                    "files.url" => 0,
                    'visits'    => 0
                }
            end
        end
    end
end

