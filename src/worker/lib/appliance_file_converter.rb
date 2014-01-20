require 'fileutils'
require 'open4'

class ApplianceFileConverter
    CMDS = {
        "vmdk" => {
            "qcow2" => {
                "cmd" => lambda {|s,t|
                    "qemu-img convert -f qcow2 -O vmdk  #{s} #{t}"
                }
            }
        },
        "qcow2" => {
            "vmdk" => {
                "cmd" => lambda {|s,t|
                    "qemu-img convert -f vmdk  -O qcow2 #{s} #{t}"
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
            error_msg = "No converter for '#{@from_format}' => '@from_format'."
            raise WorkerErrror, error_msg
        end

        cmd = cmd_lambda.call(@from_format, @from_format)

        pid, stdin, stdout, stderr = Open4.popen4(cmd)
        _, status = Process::waitpid2 pid

        if !status.success?
            raise WorkerErrror, "Converter Error '#{cmd}':\n#{stderr.read}"
        end
    end
end
