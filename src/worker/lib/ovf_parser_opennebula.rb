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

require "ovf_parser"
require "erb"
require "json"

class OVFParserOpenNebula < OVFParser
    VM_TEMPLATE = %q{
        NAME   = "<%= name %>"
        CPU    = "<%= capacity[:cpu] %>"
        MEMORY = "<%= capacity[:memory] %>"

        <% disk_array.each{|disk| %>
        <%= disk_to_one(disk) %>
        <% } %>
    }

    DISK_TEMPLATE = %q{
        DISK=[
            IMAGE = "<%= disk[:name] %>"
            <% if disk[:target] %>, TARGET = "<%= disk[:target] %>"<% end %>
        ]
    }

    def to_one
        name = get_name

        capacity = get_capacity
        cpu      = get_capacity[:cpu]
        memory   = get_capacity[:memory]

        disk_array = get_disks

        template = ERB.new(VM_TEMPLATE)
        template.result(binding).gsub(/\s*/,"")
    end

    def disk_to_one(disk)
        template = ERB.new(DISK_TEMPLATE)
        template.result(binding).strip
    end

    def to_one_json
        name = get_name

        capacity = get_capacity
        cpu      = get_capacity[:cpu]
        memory   = get_capacity[:memory]

        disks = []
        get_disks.each do |disk|
            h = {"IMAGE" => disk[:name]}
            h["TARGET"] = disk[:target] if disk[:target] if
            disks << h
        end

        {
            "NAME"   => name,
            "CPU"    => cpu,
            "MEMORY" => memory,
            "DISKS"  => disks
        }.to_json
    end
end
