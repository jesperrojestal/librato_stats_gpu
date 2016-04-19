require 'uri'
require 'yaml'
require 'socket'
require 'net/http'
require 'base64'
require 'csv'
require 'English'

module LibratoStats
  # collect and gather GPU data
  class GPU
    attr_accessor :fields, :binary, :raw_data, :csv_data

    def initialize
      # setup some fields to get gpu stats from
      @raw_data = nil
      @csv_data = nil

      # settings that can be overwritten
      @uri       = nil
      @username  = nil
      @api_token = nil
      @fields = [
        'pcie.link.gen.current',
        'pcie.link.gen.max',
        'pcie.link.width.current',
        'pcie.link.width.max',
        'utilization.gpu',
        'utilization.memory',
        'temperature.gpu',
        'power.draw',
        'power.min_limit',
        'power.max_limit',
        'clocks.current.graphics',
        'clocks.max.graphics',
        'clocks.current.sm',
        'clocks.max.sm',
        'clocks.current.memory',
        'clocks.max.memory'
      ]

      # find binary from PATH
      @bin = `/usr/bin/which nvidia-smi`.split("\n").first
      if $CHILD_STATUS.exitstatus > 0
        puts 'error: nvidia-smi was not found in PATH'
        exit 1
      end

      filename = File.realpath('librato_stats_gpu.yml')
      filename = File.realpath(ARGV[0]) if ARGV[0]

      @settings = YAML.parse_file(filename).to_ruby

      @username  = @settings['username']       if @settings['username']
      @api_token = @settings['api_token']      if @settings['api_token']
      @uri       = URI.parse(@settings['url']) if @settings['url']
      @fields    = @settings['fields']         if @settings['fields']

      raise URI::Error, "'url' setting is not a valid HTTP/HTTPS URL from #{filename}" unless @uri.is_a?(URI::HTTP)
      raise "'username' setting is missing from #{filename}" if @username.nil?
      raise "'password' setting is missing from #{filename}" if @api_token.nil?
    rescue Errno::ENOENT => e
      puts 'Settings yml file not found! (defaults to librato_stats_gpu.yml)'
      puts e.message
      exit 1
    rescue URI::Error => e
      puts "Invlid 'url' setting in yml!"
      puts e.message
      exit 1
    end

    def collect_data
      @raw_data = `#{@bin} --query-gpu=index,pci.bus_id,name,driver_version,#{@fields.join(',')} --format=csv,nounits`
      strip_spaces = ->(f) { f.strip }
      @csv_data = CSV.parse(@raw_data, headers: true, converters: strip_spaces, header_converters: strip_spaces)
    end

    def submit_data
      timestamp = Time.now.to_i

      submit_data = {
        'measure_time' => timestamp
      }

      gauge_index = 0
      @csv_data.each do |data|
        @fields.each do |label|
          raw_key = @csv_data.headers.grep(/^#{label}/).first
          key = raw_key.downcase
          key = key.tr(' ', '.')
          key = key.gsub('%', 'percent')
          key = key.gsub(/[^a-zA-Z0-9.\-]/, '')

          submit_data.merge!(
            "gauges[#{gauge_index}][source]" => "#{Socket.gethostname}.#{data['pci.bus_id']}",
            "gauges[#{gauge_index}][name]"   => "gpu.#{key}",
            "gauges[#{gauge_index}][value]"  => data[raw_key].to_s
          )
          gauge_index += 1
        end
      end

      # http connection
      http_connection = Net::HTTP.new(@uri.host, @uri.port)
      http_connection.use_ssl = true
      http_connection.verify_mode = OpenSSL::SSL::VERIFY_PEER

      # request and authentication
      request = Net::HTTP::Post.new(@uri.request_uri)
      request.basic_auth(@username, @api_token)
      request.set_form_data(submit_data)

      # get request response from server via http_connection
      response = http_connection.request(request)

      raise "Librato returned #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)
    end

    def self.collect
      obj = new
      obj.collect_data
      obj.submit_data
      obj
    end
  end
end
