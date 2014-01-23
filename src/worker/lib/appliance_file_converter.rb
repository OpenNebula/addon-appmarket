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
            FileUtils
        end
    end
end
