#!/usr/bin/env ruby
# encoding: UTF-8

# TODO: add condition symbols

require "net/http"
require "json"
require "ap"

location = "12795773"
unit = "f"
tmp_file = File.expand_path "tmux-powerline-weather.txt", "/tmp"

def conditions(location)
  data = Net::HTTP.get(URI("http://weather.yahooapis.com/forecastjson?w=#{location}"))
  data = JSON.parse(data)
  data["condition"]
end

def format(conditions, unit)
  %Q[#{conditions["temperature"]}°#{unit.upcase}]
end

##
# determines if tmp_file is a non-stale cache of the
# conditions. tmp_file is considered stale if:
# - tmp_file was last modified > 5 minutes ago
# - OR this script was last modified after tmp_file's last modification
def cache_fresh?(tmp_file)
  now = Time.now
  tmp_mtime = File.stat(tmp_file).mtime
  now - tmp_mtime < 300.0 && File.stat(__FILE__).mtime - tmp_mtime < 0.0
end

def cached_conditions(tmp_file)
  JSON.parse(File.read(tmp_file))
end

def cache_conditions(conditions, tmp_file)
  File.open(tmp_file, 'w') { |f| f.write(conditions.to_json) }
end

begin
  if File.exists?(tmp_file) && cache_fresh?(tmp_file)
    cond = cached_conditions(tmp_file)
  else
    cond = conditions(location)
    cache_conditions(cond, tmp_file)
  end

  puts format(cond, unit)
rescue
  puts "error ☹"
end
