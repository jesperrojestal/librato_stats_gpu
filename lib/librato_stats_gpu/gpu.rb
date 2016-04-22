require 'uri'
require 'yaml'
require 'socket'
require 'net/http'
require 'base64'
require 'csv'
require 'rexml/document'
require 'English'

module LibratoStats
  # collect and gather GPU data
  class GPU
    class NextIteration < RuntimeError; end

    attr_accessor :csv_fields, :xml_fields, :binary, :csv_data, :xml_data

    def initialize
      # setup some fields to get gpu stats from
      @csv_data = nil
      @xml_data = nil

      # settings that can be overwritten
      @uri       = nil
      @username  = nil
      @api_token = nil
      @csv_fields = [
        'pcie.link.gen.current',
        'pcie.link.gen.max',
        'pcie.link.width.current',
        'pcie.link.width.max',
        'utilization.gpu',
        'utilization.memory',
        'memory.total',
        'memory.used',
        'memory.free',
        'temperature.gpu',
        'fan.speed',
        'power.management',
        'power.draw',
        'power.limit',
        'enforced.power.limit',
        'power.default_limit',
        'power.min_limit',
        'power.max_limit',
        'clocks.current.graphics',
        'clocks.max.graphics',
        'clocks.current.sm',
        'clocks.max.sm',
        'clocks.current.memory',
        'clocks.max.memory',
        'clocks_throttle_reasons.applications_clocks_setting',
        'clocks_throttle_reasons.sw_power_cap',
        'clocks_throttle_reasons.hw_slowdown',
        'clocks_throttle_reasons.unknown',
        'ecc.mode.current',
        'ecc.mode.pending',
        'ecc.errors.corrected.volatile.device_memory',
        'ecc.errors.corrected.volatile.register_file',
        'ecc.errors.corrected.volatile.l1_cache',
        'ecc.errors.corrected.volatile.l2_cache',
        'ecc.errors.corrected.volatile.texture_memory',
        'ecc.errors.corrected.volatile.total',
        'ecc.errors.corrected.aggregate.device_memory',
        'ecc.errors.corrected.aggregate.register_file',
        'ecc.errors.corrected.aggregate.l1_cache',
        'ecc.errors.corrected.aggregate.l2_cache',
        'ecc.errors.corrected.aggregate.texture_memory',
        'ecc.errors.corrected.aggregate.total',
        'ecc.errors.uncorrected.volatile.device_memory',
        'ecc.errors.uncorrected.volatile.register_file',
        'ecc.errors.uncorrected.volatile.l1_cache',
        'ecc.errors.uncorrected.volatile.l2_cache',
        'ecc.errors.uncorrected.volatile.texture_memory',
        'ecc.errors.uncorrected.volatile.total',
        'ecc.errors.uncorrected.aggregate.device_memory',
        'ecc.errors.uncorrected.aggregate.register_file',
        'ecc.errors.uncorrected.aggregate.l1_cache',
        'ecc.errors.uncorrected.aggregate.l2_cache',
        'ecc.errors.uncorrected.aggregate.texture_memory',
        'ecc.errors.uncorrected.aggregate.total',
        'retired_pages.single_bit_ecc.count',
        'retired_pages.double_bit.count',
        'retired_pages.pending'
      ]

      @xml_fields = [
        'utilization/encoder_util',
        'utilization/decoder_util'
      ]

      # find binary from PATH
      @bin = `/usr/bin/which nvidia-smi`.split("\n").first
      if $CHILD_STATUS.exitstatus > 0
        raise 'error: nvidia-smi was not found in PATH'
      end

      filename = File.realpath('librato_stats_gpu.yml')
      filename = File.realpath(ARGV[0]) if ARGV[0]

      @settings = YAML.parse_file(filename).to_ruby

      @username   = @settings['username']       if @settings['username']
      @api_token  = @settings['api_token']      if @settings['api_token']
      @uri        = URI.parse(@settings['url']) if @settings['url']
      @csv_fields = @settings['csv_fields']     if @settings['csv_fields']
      @xml_fields = @settings['xml_fields']     if @settings['xml_fields']

      raise URI::Error, "'url' setting is not a valid HTTP/HTTPS URL from #{filename}" unless @uri.is_a?(URI::HTTP)
      raise "'username' setting is missing from #{filename}" if @username.nil?
      raise "'password' setting is missing from #{filename}" if @api_token.nil?
    rescue Errno::ENOENT => e
      raise e.class, "Settings yml file not found! (defaults to librato_stats_gpu.yml)\n#{e.message}"
    end

    def collect_csv_data
      raw_csv_data = `#{@bin} --query-gpu=index,pci.bus_id,name,driver_version,#{@csv_fields.join(',')} --format=csv,nounits`
      converter_strip_spaces = ->(f) { f.strip }
      @csv_data = CSV.parse(
        raw_csv_data,
        headers: true,
        header_converters: converter_strip_spaces,
        converters: converter_strip_spaces
      )
    end

    def collect_xml_data
      raw_xml_data = `#{@bin} -q --xml-format`
      @xml_data = REXML::Document.new(raw_xml_data, ignore_whitespace_nodes: :all).document.root.select { |node| node.name == 'gpu' }
    end

    def collect_data
      collect_csv_data
      collect_xml_data
    end

    def submit_data
      timestamp = Time.now.to_i

      submit_data = {
        'measure_time' => timestamp
      }

      gauge_index = 0

      @csv_data.each do |data|
        @csv_fields.each do |label|
          key = @csv_data.headers.grep(/^#{label}/).first
          name = sanitize_name(key)

          values_hash = {
            "gauges[#{gauge_index}][source]" => "#{Socket.gethostname}.#{data['pci.bus_id']}",
            "gauges[#{gauge_index}][name]"   => "gpu.#{name}"
          }

          next unless (values_hash["gauges[#{gauge_index}][value]"] = value_mapper(data[key]))

          submit_data.merge!(values_hash)
          gauge_index += 1
        end
      end

      @xml_data.each do |gpu|
        @xml_fields.each do |key|
          name = sanitize_name(key)

          values_hash = {
            "gauges[#{gauge_index}][source]" => "#{Socket.gethostname}.#{gpu.elements['pci/pci_bus_id'].text}",
            "gauges[#{gauge_index}][name]"   => "gpu.#{name}"
          }

          next unless (values_hash["gauges[#{gauge_index}][value]"] = value_mapper(gpu.elements[key].text))

          submit_data.merge!(values_hash)
          gauge_index += 1
        end
      end

      submit_data.each do |k, v|
        puts "#{k} => #{v}"
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

    private

    def sanitize_name(key)
      name = key.downcase
      name = name.tr(' /', '.')
      name = name.gsub('%', 'percent')
      name.gsub(/[^a-zA-Z0-9._\-]/, '')
    end

    def value_mapper(data)
      case data
      when '[Not Supported]'
        nil
      when 'Not Active', 'Disabled', 'No'
        '0'
      when 'Active', 'Enabled', 'Yes'
        '1'
      else
        if data =~ /\d+[.,]\d+/
          data.to_f
        else
          data.to_i
        end
      end
    end
  end
end
