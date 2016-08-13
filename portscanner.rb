#!/usr/bin/env ruby
require 'socket'
require 'timeout'
require 'ipaddr'
require 'colorize'
require 'net/ping'

DICTIONARY = {
  'ssh'     => 22,
  'telnet'  => 23,
  'smtp'    => 25,
  'tacacs'  => 49,
  'dns'     => 53,
  'dhcp'    => 68,
  'snmp'    => 623,
  'radius'  => 1812
}

IP_TEMPLATE = /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/

unless ARGV.length >= 3
  abort "Usage: ruby #{__FILE__} HOST_START HOST_END PORT_START PORT_END"
end

class String
  def is_number?
    true if Integer(self) rescue false
  end
end

module Port
  def self.port_open? ip, port, seconds=1
    Timeout::timeout(seconds) do
      begin
        TCPSocket.new(ip, port).close
        true
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
        false
      end
    end
    rescue Timeout::Error
      false
  end

  def self.host_rechable? ip
    host = Net::Ping::External.new ip
    return host.ping?
  end

  def self.protocols_set set
    ports = []
    set.each do |item|
      if DICTIONARY.has_key? item
        ports << DICTIONARY[item]
      elsif item.is_number?
        ports << item.to_i.abs
      end
    end
    return ports
  end

  def self.scan ip, port
    if port_open? ip.to_s, port
      puts "[OPEN] Port #{port}".green
    else
      puts "[NOT OPEN] Port #{port}".red
    end
  end
end

hosts_list = ARGV.select { |ip_addr| ip_addr.match IP_TEMPLATE }
possible_ports = ARGV - hosts_list
ports_list = Port.protocols_set possible_ports

hosts_list.each do |ip|
  arr = []

  if Port.host_rechable? ip
    puts "Current IP - #{ip} - is rechable".green
    ports_list.each { |port| arr << Thread.new { Port.scan(ip, port) } }
    arr.each {|t| t.join}
  else
    puts "Current IP - #{ip} - is unrechable".red
  end
end
