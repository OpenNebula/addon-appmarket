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

require 'rubygems'
require 'nokogiri'

#
# Parses an OVF file for OpenNebula consumption
#
class OVFParser
    # Parses the xml OVF document
    # xml_file_path -> path to the file containing the OVF metadata
    def initialize(xml_source)
        @doc = Nokogiri::XML(File.read(xml_source))

        # Support for single VMs only (get the fist one)
        @virtual_system = @doc.xpath("//ovf:VirtualSystem")[0]
        @virtual_hw     = @virtual_system.xpath("//ovf:VirtualHardwareSection")
    end

    # Get files to register, returns an array with the file names
    def get_disk_files
        disk_elements = @doc.xpath("//ovf:Disk")
        file_elements = @doc.xpath("//ovf:File")

        disk_files = Hash.new
        disk_elements.each do |disk|
            disk_id  = disk.attribute("diskId").value
            file_ref = disk.attribute("fileRef").value

            href = @doc.xpath("//ovf:File[@ovf:id='#{file_ref}']").attribute('href').value
            disk_files[disk_id] = href
        end

        disk_files
    end

    # Return list of SCSI instance ids
    def get_scsi_iids
        scsi_xpath    = "//ovf:Item[rasd:ResourceType[contains(text(),'6')]]"
        iid_xpath     = "rasd:InstanceID"
        name_xpath    = "rasd:ElementName"

        iids          = Array.new

        @virtual_hw.xpath(scsi_xpath).each{|bus|
            next if bus.xpath(name_xpath).text.downcase["scsi"]
            iids << bus.xpath(iid_xpath).text
        }

        return iids
    end

    # Get disks to be present in the VM, returns an array with
    # DISK string sections
    #def get_disks(created_images)
    def get_disks
        # Get the instances ids of the disks
        iids           = get_scsi_iids

        # Get all the disks described in the HW section
        disks_xpath   = "//ovf:Item[rasd:ResourceType[contains(text(),'17')]]"
        cds_xpath     = "//ovf:Item[rasd:ResourceType[contains(text(),'15')]]"

        iid_xpath     = "rasd:InstanceID"
        aop_xpath     = "rasd:AddressOnParent"
        hostr_xpath   = "rasd:HostResource"

        disk_elements = @virtual_hw.xpath(disks_xpath)

        disk_array = Array.new(disk_elements.size){|i|
            disk  = disk_elements[i]

            iid     = disk.xpath(iid_xpath).text
            aop     = disk.xpath(aop_xpath).text
            hostr   = disk.xpath(hostr_xpath).text.gsub(/^ovf:\/disk\//,"")

            if iids.include?(iid) # scsi
                target="sd" + ("a".unpack('C')[0]+aop.to_i).chr
            else # ide
                target="hd" + ("a".unpack('C')[0]+aop.to_i).chr
            end

            {
                :name   => hostr,
                :target => target,
                :path   => get_disk_files[hostr]
            }
        }
    end

    # Get capacity (CPU & MEMORY)
    def get_capacity
        cpu_xpath =
      "//ovf:Item[rasd:ResourceType[contains(text(),'3')]]/rasd:VirtualQuantity"

        cpu = @virtual_hw.xpath(cpu_xpath).text

        memory_xpath =
      "//ovf:Item[rasd:ResourceType[contains(text(),'4')]]/rasd:VirtualQuantity"

        memory = @virtual_hw.xpath(memory_xpath).text

      return {:cpu => cpu, :memory => memory}
    end

    def get_name
        @virtual_system.xpath("ovf:Name").text
    end

    def get_buses
        # Check for SCSI buses
        scsi_xpath    = "//ovf:Item[rasd:ResourceType[contains(text(),'6')]]"
        address_xpath = "rasd:Address"
        subtype_xpath = "rasd:ResourceSubType"
        name_xpath    = "rasd:ElementName"

        buses = Array.new

        @virtual_hw.xpath(scsi_xpath).each{|bus|
            next if bus.xpath(name_xpath).text.downcase["scsi"]
            address = bus.xpath(address_xpath).text
            subtype = bus.xpath(subtype_xpath).text
            bus_str =  "<devices><controller type='scsi' index='#{address}'"
            bus_str << " model='#{subtype}'/></devices>"
            buses   << bus_str
        }

        return buses
    end
end
