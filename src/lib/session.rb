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

require 'digest/sha1'

class Session
    PERMISSIONS = {
        :user => {
            :create => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :show => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :delete => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :update => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :list => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :enable => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :schema => {
                :anonymous => AppMarket::User::SCHEMA,
                :user      => AppMarket::User::SCHEMA,
                :worker    => AppMarket::User::SCHEMA,
                :admin     => AppMarket::User::ADMIN_SCHEMA
            }
        },
        :appliance => {
            :create => {
                :anonymous  => false,
                :user       => true,
                :worker     => false,
                :admin      => true
            },
            :show => {
                :anonymous  => true,
                :user       => true,
                :worker     => false,
                :admin      => true
            },
            :delete => {
                :anonymous  => false,
                :user       => true,
                :worker     => false,
                :admin      => true
            },
            :update => {
                :anonymous  => false,
                :user       => true,
                :worker     => false,
                :admin      => true
            },
            :list => {
                :anonymous  => true,
                :user       => true,
                :worker     => false,
                :admin      => true
            },
            :download => {
                :anonymous  => true,
                :user       => true,
                :worker     => false,
                :admin      => true
            },
            :clone => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :schema => {
                :anonymous => AppMarket::Appliance::USER_SCHEMA,
                :user      => AppMarket::Appliance::USER_SCHEMA,
                :worker    => AppMarket::Appliance::ADMIN_SCHEMA,
                :admin     => AppMarket::Appliance::ADMIN_SCHEMA
            }
        },
        :job => {
            :create => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :show => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :delete => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :list => {
                :anonymous  => false,
                :user       => false,
                :worker     => false,
                :admin      => true
            },
            :schema => {
                :anonymous => AppMarket::Job::SCHEMA,
                :user      => AppMarket::Job::SCHEMA,
                :worker    => AppMarket::Job::SCHEMA,
                :admin     => AppMarket::Job::SCHEMA
            }
        },
        :worker => {
            :list_jobs => {
                :anonymous  => false,
                :user       => false,
                :worker     => true,
                :admin      => true
            },
            :next_job => {
                :anonymous  => false,
                :user       => false,
                :worker     => true,
                :admin      => true
            },
            :job_callback => {
                :anonymous  => false,
                :user       => false,
                :worker     => true,
                :admin      => true
            }
        }
    }

    def initialize(env)
        @user = authenticate(env)
    end

    def authorize(env)
        perms = case env["REQUEST_METHOD"]
        when 'GET', 'HEAD'
            case env["PATH_INFO"]
            when /^\/job$/
                PERMISSIONS[:job][:list]
            when /^\/job\/\w+$/
                PERMISSIONS[:job][:show]
            when /^\/user$/
                PERMISSIONS[:user][:list]
            when /^\/user\/\w+$/
                PERMISSIONS[:user][:show]
            when /^\/appliance$/
                PERMISSIONS[:appliance][:list]
            when /^\/appliance\/\w+$/
                PERMISSIONS[:appliance][:show]
            when /^\/appliance\/\w+\/download(\/\d+)?$/
                PERMISSIONS[:appliance][:download]
            when /^\/worker\/\w+\/nextjob$/
                PERMISSIONS[:worker][:next_job]
            when /^\/worker\/\w+\/job$/
                PERMISSIONS[:worker][:list_jobs]
            when /^\/favicon.ico$/
                true
            end
        when 'DELETE'
            case env["PATH_INFO"]
            when /^\/job\/\w+$/
                PERMISSIONS[:job][:delete]
            when /^\/user\/\w+$/
                PERMISSIONS[:user][:delete]
            when /^\/appliance\/\w+$/
                PERMISSIONS[:appliance][:delete]
            end
        when 'PUT'
            case env["PATH_INFO"]
            when /^\/user\/\w+$/
                PERMISSIONS[:user][:update]
            when /^\/appliance\/\w+$/
                PERMISSIONS[:appliance][:update]
            end
        when 'POST'
            case env["PATH_INFO"]
            when /^\/job$/
                PERMISSIONS[:job][:create]
            when /^\/user$/
                PERMISSIONS[:user][:create]
            when /^\/appliance$/
                PERMISSIONS[:appliance][:create]
            when /^\/appliance\/\w+\/clone$/
                PERMISSIONS[:appliance][:clone]
            when /^\/user\/\w+\/enable$/
                PERMISSIONS[:user][:enable]
            when /^\/worker\/\w+\/job\/\w+\/(done|error|update|cancel)$/
                PERMISSIONS[:worker][:job_callback]
            end
        end

        if perms.instance_of?(Hash)
            perms[role]
        else
            false
        end
    end

    def schema(resource)
        PERMISSIONS[resource][:schema][role].dup
    end

    def allowed_catalogs
        if anonymous?
            [AppMarket::Appliance::PUBLIC_CATALOG]
        elsif user?
            if  @user['catalogs']
                [AppMarket::Appliance::PUBLIC_CATALOG] + @user['catalogs']
            else
                [AppMarket::Appliance::PUBLIC_CATALOG]
            end
        elsif admin?
            nil
        end
    end

    def admin?
        role == :admin
    end

    def user?
        role == :user
    end

    def worker?
        role == :worker
    end

    def anonymous?
        role == :anonymous
    end

    def role
        if @user.nil?
            :anonymous
        elsif @user['role'] == AppMarket::User::ADMIN_ROLE
            :admin
        elsif @user['role'] == AppMarket::User::WORKER_ROLE
            :worker
        else
            :user
        end
    end

    def name
        @user['username'] if @user
    end

    # Retrieve the publisher name of the session
    def publisher
        @user['organization'] if @user
    end

    private

    def authenticate(env)
        auth = Rack::Auth::Basic::Request.new(env)

        if auth.provided? && auth.basic?
            username, password = auth.credentials

            #sha1_pass = Digest::SHA1.hexdigest(password)
            AppMarket::UserCollection.retrieve(username, password)
        else
            nil
        end
    end
end
