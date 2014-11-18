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
    class Collection
        # Return the value of the @data entry
        #
        # @param [String] key
        # @return [String, Integer, Array] It depends on the value in @data[key]
        def [](key)
            return @data[key]
        end

        # @return [Hash] containing the resource information
        def to_hash
            if @data.empty?
                return {"_id" => {"$oid" => @mongo_object_id}}
            else
                return @data
            end
        end

        # @return [String] mongo_object_id string
        def mongo_object_id
            @data['_id'].to_s
        end

        protected

        # Turn a string ID representation into a BSON::ObjectId
        #
        # @param [String] id_str id of the object
        # @return [BSON::ObjectId]
        def self.str_to_mongo_object_id(id_str)
            BSON::ObjectId(id_str)
        end

        def self.collection
            AppMarket::DB[self::COLLECTION_NAME]
        end

        # Check if the result is an error
        #
        # @param [Array] result, contains the status and a hash with info
        # @return [Boolean]
        def self.is_error?(result)
            if result.is_a?(Array)
                if [200, 201, 204].include?(result[0])
                    return false
                else
                    return true
                end
            end

            return false
        end
    end

    class PoolCollection < Collection

        include Enumerable

        def initialize(session, selector, opts)
            opts[:sort] ||= ['_id', Mongo::ASCENDING]
            @data = []
            @session = session
        end

        # Iterates over every element in the collection and calls the block
        #   with an instance obtained calling the factory method. The factory
        #   method should be implemented by subclasses of PoolCollection
        def each(&block)
            @data.each { |pelem|
                block.call self.factory(@session, pelem)
            }
        end

        # Return the instance obtained calling the factory method of the
        #   element in the given index. The factory method should be
        #   implemented by subclasses of PoolCollection
        #
        # @param [Integer] index
        # @return [AppMarket::Collection] It depends on the implemented
        #   factory method
        def [](index)
            # TODO Handle exception if the index is out of bound
            self.factory(@session, @data[index])
        end

        # Check if the @data array is empty
        #
        # @return [true, false]
        def empty?
            return @data.empty?
        end

        # @return [Integer] size of the pool
        def size
            return @data.size
        end

        # Returns de @data array
        #
        # @return [Array]
        def to_a
            return @data
        end
    end
end
