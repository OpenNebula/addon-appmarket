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
    class Appliance < Collection
        # Appliances will be created by default in this catalog
        #   This catalog is accesible for all the users even anonymous ones.
        PUBLIC_CATALOG = 'community'

        STATUS = %w{init ready converting downloading publishing error}

        FILE_SCHEMA = {
            :type => :object,
            :properties => {
                'name' => {
                    :type => :string
                },
                'type' => {
                    :type => :string,
                    :enum => %w{OS CDROM DATABLOCK},
                    :default => 'OS'
                },
                'driver' => {
                    :type => :string
                },
                'dev_prefix' => {
                    :type => :string
                },
                # DEPRECATED, user first level attr in app instead
                'hypervisor' => {
                    :type => :string,
                    :enum => %w{VMWARE XEN KVM all},
                    :default => 'all'
                },
                # DEPRECATED, user first level attr in app instead
                'format' => {
                    :type => :string,
                    :enum => %w{raw vmdk qcow2 vdi},
                    :default => 'raw'
                },
                'size' => {
                    :type => :string,
                    :required => true
                },
                'compression' => {
                    :type => :string,
                    :enum => %w{bz2 gzip none},
                    :default => 'none'
                },
                # DEPRECATED, user first level attr in app instead
                'os-id' => {
                    :type => :string,
                    :default => ''
                },
                # DEPRECATED, user first level attr in app instead
                'os-release' => {
                    :type => :string,
                    :default => ''
                },
                # DEPRECATED, user first level attr in app instead
                'os-arch' => {
                    :type => :string,
                    :default => 'x86_64'
                },
                'md5' => {
                    :type => :string
                },
                'sha1' => {
                    :type => :string
                }
            }
        }

        ADMIN_FILE_SCHEMA = FILE_SCHEMA.deep_merge({
            :properties => {
                'url' => {
                    :type => :string,
                    :format => :uri
                }
            }
        })

        USER_FILE_SCHEMA = FILE_SCHEMA.deep_merge({
            :properties => {
                'url' => {
                    :type => :string,
                    :format => :uri,
                    :required => true
                }
            }
        })

        SCHEMA = {
            :type => :object,
            :properties => {
                'name' => {
                    :type => :string,
                    :required => true
                },
                'source' => {
                    :type => :string,
                    :format => :uri
                },
                'source_type' => {
                    :type => :string,
                    :enum => %w{ova}
                },
                'tags' => {
                    :type => :array,
                    :items => {
                        :type => :string
                    },
                    :default => []
                },
                'description' => {
                    :type => :string,
                    :required => true
                },
                'short_description' => {
                    :type => :string,
                    :required => true
                },
                'version' => {
                    :type => :string,
                    :default => '1.0'
                },
                'opennebula_version' => {
                    :type => :string,
                    :default => 'all'
                },
                'opennebula_template' => {
                    :type => :string
                },
                'visits' => {
                    :type => :null,
                    :default => 0
                },
                'downloads' => {
                    :type => :null,
                    :default => 0
                },
                'os-id' => {
                    :type => :string,
                    :default => ''
                },
                'os-release' => {
                    :type => :string,
                    :default => ''
                },
                'os-arch' => {
                    :type => :string,
                    :default => 'x86_64'
                },
                'hypervisor' => {
                    :type => :string,
                    :enum => %w{VMWARE XEN KVM all},
                    :default => 'all'
                },
                'format' => {
                    :type => :string,
                    :enum => %w{raw vmdk qcow2 vdi},
                    :default => 'raw'
                }
            }
        }

        ADMIN_SCHEMA = {
            :extends => SCHEMA,
            :properties => {
                'catalog' => {
                    :type => :string,
                    :default => PUBLIC_CATALOG
                },
                'publisher' => {
                    :type => :string
                },
                'logo' => {
                    :type => :string,
                    :format => :uri,
                    :default => "/img/logos/default.png"
                },
                'status' => {
                    :type => :string,
                    :default => 'init',
                    :enum => AppMarket::Appliance::STATUS,
                },
                'files' => {
                    :type => :array,
                    :items => ADMIN_FILE_SCHEMA,
                    :required => true
                }
            }
        }

        USER_SCHEMA = {
            :extends => SCHEMA,
            :properties => {
                'catalog' => {
                    :type => :null,
                    :default => PUBLIC_CATALOG
                },
                'logo' => {
                    :type => :null,
                    :format => :uri,
                    :default => "/img/logos/default.png"
                },
                'status' => {
                    :type => :null,
                    :default => 'ready',
                    :enum => AppMarket::Appliance::STATUS,
                },
                'files' => {
                    :type => :array,
                    :items => USER_FILE_SCHEMA,
                    :required => true
                }
            }
        }

        # This method should be used only by the factory method, to retrieve
        #   an existing resource from the database use the AppCollecion.get
        #   method
        def initialize(session, data)
            @data = data
            @session = session
        end

        # Delete the appliance from the database and cancel the associated
        #   jobs of the appliance.
        #
        # @return [Integer, Hash] status code and hash with the error message
        def delete
            begin
                # Remove associated jobs
                job_selector = {
                    'appliance_id' => self.mongo_object_id
                }

                job_collection = AppMarket::JobCollection.new(@session, job_selector)
                job_collection.info
                job_collection.each { |job|
                    job.cancel
                }

                job_hash = {
                    'name'         => 'delete',
                    'appliance_id' => self.mongo_object_id
                }

                if !@data['source'].nil? && !@data['source'].empty?
                    JobCollection.create(@session, job_hash)
                end

                # The app is removed insted of keeping it until all the jobs
                #   are cancelled?
                AppCollection.collection.remove(
                    :_id => Collection.str_to_mongo_object_id(self.mongo_object_id))
            rescue BSON::InvalidObjectId
                return [404, {"message" => $!.message}]
            end

            return [200, {}]
        end

        # Query the database to retrieve the information of the appliance
        #
        # @return [Integer, Hash] status code and hash with the info
        def info
            begin
                @data = AppCollection.collection.find_one(
                            :_id => Collection.str_to_mongo_object_id(self.mongo_object_id))
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
            validator = Validator::Validator.new(
                :default_values => false,
                :check_required => false,
                :delete_extra_properties => true
            )

            begin
                validator.validate!(opts, @session.schema(:appliance))
            rescue Validator::ParseException
                return [400, {"message" => $!.message}]
            end

            @data = @data.deep_merge(opts)

            if @data['files']
                @data['files'].each {|f| f['hypervisor'] = @data['hypervisor']}
            end

            AppCollection.collection.update(
                    {:_id => Collection.str_to_mongo_object_id(self.mongo_object_id)},
                    @data)

            return [200, {}]
        end

        # Get the stored size of a file
        #   The role of the user will be used to filter the appliance
        #
        # @param [Integer] file_id the fiel file that will be downloaded, default value: 0
        # @return [String] size of the file
        def file_size(file_id=0)
            @data['files'][file_id.to_i]['size']
        end

        # Get the link to download a file
        #   The role of the user will be used to filter the appliance
        #
        # @param [Integer] file_id the fiel file that will be downloaded, default value: 0
        # @return [String] url of the file
        def file_url(file_id=0)
            AppCollection.collection.update(
                    {:_id => Collection.str_to_mongo_object_id(self.mongo_object_id)},
                    "$inc" => { 'downloads' => 1 })

            @data['files'][file_id.to_i]['url']
        end
    end
end
