# frozen_string_literal: true

module Samson
  module ProcessUtils
    ATTRIBUTES = ['pid', 'ppid', 'gid', 'user', 'start', 'args'].freeze

    class Process
      attr_accessor *ATTRIBUTES

      def initialize(args)
        ATTRIBUTES.each_with_index do |name, index|
          instance_variable_set("@#{name}", args[index])
        end
      end
    end

    class << self
      def ps_list
        pipe = IO.popen("ps -eo #{ATTRIBUTES.join(',')}")
        pipe.readlines[1..-1].map do |line|
          Process.new line.lstrip.split(/\s+/, 6)
        end
      end

      def report_to_statsd
        ps_list.each do |process|
          timeout = Time.parse(process.start) < Time.now - Rails.application.config.samson.deploy_timeout
          tags = ATTRIBUTES.map { |attr| "#{attr}:#{process.send(attr)}" }
          Samson.statsd.gauge("process.start.time", (timeout ? 2.0 : 1.0), tags: tags)
        end
      end
    end
  end
end
