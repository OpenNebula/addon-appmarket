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

require 'fileutils'
require 'open4'

class ApplianceFileConverter
    class ApplianceFileConverterError < RuntimeError; end

    CMDS = {
        "vmdk" => {
            "qcow2" => {
                "cmd" => lambda {|s,t|
                    "qemu-img convert -O qcow2 #{s} #{t}"
                }
            },
            "raw" => {
                "cmd" => lambda {|s,t|
                    "qemu-img convert -O raw #{s} #{t}"
                }
            }
        },
        "qcow2" => {
            "vmdk" => {
                "cmd" => lambda {|s,t|
                    "qemu-img convert -O vmdk #{s} #{t}"
                }
            },
            "raw" => {
                "cmd" => lambda {|s,t|
                    "qemu-img convert -O raw #{s} #{t}"
                }
            }
        },
        "raw" => {
            "qcow2" => {
                "cmd" => lambda {|s,t|
                    "qemu-img convert -O qcow2 #{s} #{t}"
                }
            },
            "vmdk" => {
                "cmd" => lambda {|s,t|
                    "qemu-img convert -O vmdk #{s} #{t}"
                }
            }
        }
    }

    def initialize(from_format, format)
        @from_format = from_format
        @format      = format
    end

    def convert(source_path, target_path)
        begin
            cmd_lambda = CMDS[@from_format][@format]["cmd"]
        rescue
            error_msg = "No converter for '#{@from_format}' => '#{@format}'."
            raise ApplianceFileConverterError, error_msg
        end

        cmd = cmd_lambda.call(source_path, target_path)

        pid, stdin, stdout, stderr = Open4.popen4(cmd)
        _, status = Process::waitpid2 pid

        if !status.success?
            FileUtils.rm_f(target_path)
            raise ApplianceFileConverterError, "Converter Error '#{cmd}':\n#{stderr.read}"
        else
            File.chmod(0644, target_path)
        end
    end
end
