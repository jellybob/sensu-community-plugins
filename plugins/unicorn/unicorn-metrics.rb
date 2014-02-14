#!/usr/bin/env ruby
#
# Push Unicorn stats into graphite
# ===
# 
# Copyright 2014 Jon Wood https://github.com/jellybob
#
# Heavily based on the varnish-metrics plugin.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'unicorn'

class UnicornMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
    :description => "Metric naming scheme, text to prepend to metric",
    :short => "-s SCHEME",
    :long => "--scheme SCHEME",
    :default => "#{Socket.gethostname}.unicorn"

  option :name,
    :description => "A name for this Unicorn cluster, to distinquish between multiple Unicorns",
    :short => "-n NAME",
    :long => "--name NAME"

  option :unicorn_socket,
    :description => "The Unicorn socket to query for metrics",
    :short => "-s SOCKET",
    :long => "--socket SOCKET"

  def graphite_path_sanitize(path)
    # accept only a small set of chars in a graphite path and convert anything else
    # to underscores
    path.gsub(/[^a-zA-Z0-9_-]/, '_')
  end

  def run
    begin
      socket = config[:unicorn_socket]
      stats = Raindrops::Linux.unix_listener_stats([ socket ])

      %w(active queued).each do |stat|
        path = "#{config[:scheme]}"
        if config[:name]
          path += "." + graphite_path_sanitize(config[:name])
        end
        path += "." + graphite_path_sanitize(stat)
        output path, stats[socket].send(stat)
      end
    rescue Exception => e
      puts "Error: exception: #{e}"
      puts e.backtrace
      critical
    end
    ok
  end

end
