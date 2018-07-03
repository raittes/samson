# frozen_string_literal: true

module Samson
  module ProcessUtils
    ATTRIBUTES = ['pid', 'ppid', 'gid', 'pcpu', 'user', 'start', 'args'].freeze
    WHITELISTS = ['puma'].freeze

    class << self
      def ps_list
        pipe = IO.popen("ps -eo #{ATTRIBUTES.join(',')} | grep -v #{WHITELISTS.join(',')}")
        pipe.readlines[1..-1].map do |line|
          Hash[ATTRIBUTES.zip line.lstrip.split(/\s+/, 7)]
        end
      end

      def report_to_statsd
        ps_list.each do |process|
          timeout = Time.parse(process.fetch('start')) < Time.now - Rails.application.config.samson.deploy_timeout
          tags = ATTRIBUTES.map { |attr| "#{attr}:#{process.fetch(attr)}" }
          Samson.statsd.gauge("process.start.time", (timeout ? 2.0 : 1.0), tags: tags)
        end
      end
    end
  end
end
