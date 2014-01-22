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

require 'bcrypt'

module AppMarket
    class User < Collection
        # User will be created by default in this role
        USER_ROLE   = 'user'
        ADMIN_ROLE  = 'admin'
        WORKER_ROLE = 'worker'

        SCHEMA = {
            :type => :object,
            :properties => {
                'organization' => {
                    :type => :string,
                    :required => true
                },
                'first_name' => {
                    :type => :string,
                    :required => true
                },
                'last_name' => {
                    :type => :string,
                    :required => true
                },
                'username' => {
                    :type => :string,
                    :required => true
                },
                'password' => {
                    :type => :string,
                    :required => true
                },
                'website' => {
                    :type => :string,
                    :format => :uri
                },
                'email' => {
                    :type => :string,
                    :required => true
                },
                'role' => {
                    :type => :null,
                    :default => USER_ROLE
                },
                'status' => {
                    :type => :null,
                    :default => 'disabled'
                },
                'catalogs' => {
                    :type => :array,
                    :items => {
                        :type => :string
                    },
                    :default => []
                }
            }
        }

        ADMIN_SCHEMA = {
            :extends => SCHEMA,
            :properties => {
                'role' => {
                    :type => :string,
                    :enum => %w{user admin worker},
                },
                'status' => {
                    :type => :string
                }
            }
        }

        # This method should be used only by the factory method, to retrieve
        #   an existing resource from the database use the UserCollection.get
        #   method
        def initialize(session, data)
            @session = session
            @data = data
        end

        # Delete the appliance from the database and cancel the associated
        #   jobs of the appliance.
        #
        # @return [Integer, Hash] status code and hash with the error message
        def delete
            begin
                AppCollection.collection.remove(
                    :_id => Collection.str_to_object_id(self.object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            # TODO return code
            return [200, {}]
        end

        def enable
            AppCollection.collection.update(
                    {:_id => Collection.str_to_object_id(self.object_id)},
                    {'$set' => {'status' => 'enabled'}})

            # TODO check if update == success

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

        # Update the user
        #
        # @param [Hash] opts Hash containing the values to be updated.
        #   The information provided in this hash will be merged with the
        #   original information
        # @return [Integer, Hash] status code and hash with the error message
        def update(opts)
            # TODO check opts keys
            if !hash['password']
                hash['password'] = user['password']
            else
                hash['password'] = User.generate_password(hash['password'])
            end

            validator = Validator::Validator.new(
                :default_values => false,
                :delete_extra_properties => true
            )
            validator.validate!(hash, @session.schema(:user))

            @data = @data.deep_merge(opts)
            AppCollection.collection.update(
                    {:_id => Collection.str_to_object_id(self.object_id)},
                    @data)

            # TODO check if update == success

            return [200, {}]
        end

        # Generate a password to be stored in the DB
        # @param [String] password
        # @return [String]
        def self.generate_password(password)
            BCrypt::Password.create(password).to_s
        end

        # Check if the password provided match the user password
        # @param [User] user info from the DB
        # @param [String] password provided by the user
        # @return [true, false]
        def self.check_password(user, password)
            bcrypt_pass = BCrypt::Password.new(user['password'])
            return (bcrypt_pass == password)
        end
    end
end
