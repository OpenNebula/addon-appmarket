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

require 'mail'
require 'erb'

module Mailer
  MESSAGE = %q{
Hi

Your account for the OpenNebula Marketplace has been enabled

Username: <%= username %>

Please, do not forget to subscribe to the OpenNebula forum [1]

* How to Develop your Appliance?
This guide [2] will show you how to create OpenNebula compatible images for the Marketplace

* How to Post your Appliance?
Log in with you Developer account int The OpenNebula Marketplace [3]. After that, you will be able to click your username in the navigation bar and select "Create new Appliance".

Kind regards

[1] https://forum.opennebula.org/
[2] http://docs.opennebula.org/stable/operation/vm_setup/context_overview.html
[3] https://marketplace.opennebula.systems/
}

  if AppMarket::CONF['mail']
    Mail.defaults do
      delivery_method :smtp, AppMarket::CONF['mail']
    end

    def self.send_enable(email, username)
      Mail.deliver do
        from    AppMarket::CONF['mail'][:user_name]
        to      email
        subject 'OpenNebula Marketplace account'
        body    ERB.new(MESSAGE).result(binding)
      end
    end
  end
end

