require 'ovf_parser_opennebula'
require 'appliance_file_converter'

require 'fileutils'
require 'tmpdir'
require 'uuidtools'
require 'open4'

################################################################################
# ApplianceFileHandler
################################################################################

class ApplianceFileHandler
    def initialize(hash = nil)
        @hash = hash || Hash.new
    end

    # Hash implementation
    def to_hash; @hash; end
    def [](key); @hash[key]; end
    def []=(key, value); @hash[key] = value; end

    # Static methods
    def self.register(hash)
        source = hash[:path]
        name   = hash[:name] || source.split("/")[-1]
        target = hash[:target] if hash[:target]

        uuid = UUIDTools::UUID.random_create.to_s

        path = File.join(AppMarket::CONF[:repo], uuid)
        url  = File.join(AppMarket::CONF[:base_uri], uuid)

        FileUtils.mkdir_p(CONF[:repo])
        FileUtils.mv(source, path)

        digests = self.digests(path)

        self.new({
            "name" => name,
            "url"  => url,
            "size" => File.size?(path).to_s,
            "md5"  => digests[:md5],
            "sha1" => digests[:sha1]
        })
    end

    def self.digests(path)
        md5sum  = Digest::MD5.new
        sha1sum = Digest::SHA1.new

        File.open(path, 'rb') do |io|
            buffer = String.new
            while io.read(4096, buffer)
                md5sum.update(buffer)
                sha1sum.update(buffer)
            end
        end

        {
            :md5  => md5sum.to_s,
            :sha1 => sha1sum.to_s
        }
    end
end

################################################################################
# ApplianceHandler Processing
################################################################################

class ApplianceHandler
    class ApplianceHandlerError < RuntimeError; end

    attr_accessor :files, :body

    def initialize(body)
        @body   = body
        @source = @body["source"]
        @files  = @body["files"] || Array.new
    end

    def temp_dir
        return @temp_dir if @temp_dir

        FileUtils.mkdir_p(AppMarket::CONF[:temp_dir])
        @temp_dir = Dir.mktmpdir(nil, AppMarket::CONF[:temp_dir])
    end

    def delete_temp_dir
        FileUtils.rm_r(temp_dir)
    end

    def download_cmd
        if !defined?(@curl_exists) or !defined?(@wget_exists)
            which_curl = `which curl`
            @curl_exists = $?.exitstatus == 0

            which_wget = `which wget`
            @wget_exists = $?.exitstatus == 0
        end

        if @curl_exists
            "curl -s #{@source}"
        elsif @wget_exists
            "wget -q #{@source} -O-"
        else
            raise ApplianceHandlerError, "No curl or wget found."
        end
    end

    def to_hash
        inherit_file_params = Hash.new

        %w(os-id os-release os-arch hypervisor format).each do |p|
            if (v = @body[p])
                inherit_file_params[p] = v
            end
        end

        {
            "files" => @files.collect{|e| e.merge(inherit_file_params)},
            "opennebula_template" => @body["opennebula_template"]
        }
    end

    def convert(files, from_format, format)
        converter = ApplianceFileConverter.new(from_format, format)

        files.each do |file|
            uuid        = file["url"].split("/")[-1]
            name        = file["name"]

            source_path = File.join(AppMarket::CONF[:repo],uuid)
            target_path = File.join(temp_dir,uuid)

            converter.convert(source_path, target_path)

            file_hash = {
                :path => target_path,
                :name => name
            }

            appliance_file = ApplianceFileHandler.register(file_hash)
            @files << appliance_file.to_hash
        end
    end

    UUID_REGEX = /[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/
    def delete_files
        @body["files"].each do |file|
            uuid = File.basename(file["url"])
            if uuid.match(UUID_REGEX)
                path = File.join(CONF[:repo],uuid)
                FileUtils.rm_f(path)
            end
        end
    end
end

class OVA < ApplianceHandler
    def unpack
        pid, stdin, stdout, stderr = Open4.popen4("#{download_cmd} | tar -xf- -C #{temp_dir}")
        _, status = Process::waitpid2 pid

        if !status.success?
            raise ApplianceHandlerError, "Download error:\n#{stderr.read}"
        end
    end

    def register_files
        ovf_file = Dir["#{temp_dir}/*.ovf"][0]

        ovf = OVFParserOpenNebula.new(ovf_file)
        ovf.get_disks.each do |disk|
            disk[:path]    = File.join(temp_dir, disk[:path])
            appliance_file = ApplianceFileHandler.register(disk)
            @files << appliance_file.to_hash
        end

        @body["opennebula_template"] = ovf.to_one_json
    end
end
