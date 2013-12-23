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

    class UserCollection < PoolCollection
        COLLECTION_NAME = "users"

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
        # @param [Session] session an instance of Session containing
        #   the user permisions
        # @return [Integer, Array] status code and array with the resources
        def info
            selector = @selector.deep_merge(UserCollection.generate_filter(@session, nil))
            opts = @opts.deep_merge({:fields => UserCollection.exclude_fields(@session)})

            @data = UserCollection.collection.find(selector, opts).to_a

            return [200, self.to_a]
        end

        # Create a new user
        #
        # @param [Session] session an instance of Session containing the user permisions
        # @param [Hash] hash containing the values of the resource
        # @return [Integer, Hash] status code and hash containing the error
        #   message or the info of the resource
        def self.create(session, hash)
            validator = Validator::Validator.new(
                :default_values => true,
                :delete_extra_properties => false
            )

            begin
                validator.validate!(hash, session.schema(:user))
            rescue Validator::ParseException
                return [400, {"message" => $!.message}]
            end

            hash['password'] = AppConverter::User.generate_password(hash['password'])

            begin
                object_id = collection.insert(hash, {:w => 1})
            rescue Mongo::OperationFailure
                return [400, {"message" => "already exists"}]
            end

            user = UserCollection.get(session, object_id.to_s)
            return [201, user.to_hash]
        end

        # Retrieve the resource from the database. This method must be use
        #   to retrieve the resource instead of Appliance.new
        #
        # @param [Session] session an instance of Session containing the
        #   user permisions
        # @param [String] object_id id of the resource
        # @return [AppConverter::Appliance] depends on the factory method
        def self.get(session, object_id)
            filter = generate_filter(session, object_id)
            fields = exclude_fields(session)

            begin
                data = collection.find_one(filter, :fields => fields)
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            if data.nil?
                return [404, {"message" => "Appliance not found"}]
            end

            return self.factory(session, data)
        end

        def self.bootstrap(user_config_hash)
            if collection.count == 0
                collection.create_index('username', :unique => true)
                collection.create_index('organization', :unique => true)

                default_params = {
                    'role'     => 'admin',
                    'status'   => 'enabled'
                }

                user_hash = user_config_hash.merge(default_params)
                user_hash['password'] = AppConverter::User.generate_password(user_hash.delete('password'))

                collection.insert(user_hash)
            end
        end

        #
        def self.retrieve(username, password)
            user = collection.find_one(
                "username" => username,
                "status" => "enabled"
                )

            if user && AppConverter::User.check_password(user, password)
                return user
            else
                return nil
            end
        end

        protected

        # Default Factory Method for the Pools
        def self.factory(session, pelem)
            User.new(session, pelem)
        end

        def factory(session, pelem)
            UserCollection.factory(session, pelem)
        end

        # Generate a Hash containing the filter to be applied to the query
        #
        # @params [Session] session an instance of Session containing the user permisions
        # @param [String] user_id id of the appliance
        # @return [Hash] a hash containing the contraints
        def self.generate_filter(session, user_id)
            filter = Hash.new

            if user_id
                filter["_id"] = BSON::ObjectId(user_id)
            end

            filter
        end

        # Generate a Hash containing the fields to be excluded, a key with value
        #   0 will be excluded.
        #
        # @params [Session] session an instance of Session containing the user permisions
        # @return [Hash] a hash of fields
        def self.exclude_fields(session)
            {
                'password' => 0
            }
        end
    end
end

