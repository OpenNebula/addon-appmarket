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
    class Collection

        protected

        # Turn a string ID representation into a BSON::ObjectId
        #
        # @param [String] id_str id of the object
        # @return [BSON::ObjectId]
        def self.str_to_object_id(id_str)
            BSON::ObjectId(id_str)
        end

        def self.collection
            DB[self::COLLECTION_NAME]
        end
    end

    class PoolCollection < Collection

        def initialize
            @data = []
        end

        # Iterates over every PoolElement in the Pool and calls the block with a
        # a PoolElement obtained calling the factory method
        # block:: _Block_
        def each(&block)
            @data.each { |pelem|
                block.call self.factory(pelem)
            }
        end
    end
end
