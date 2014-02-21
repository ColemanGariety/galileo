# encoding: utf-8
# require "terminal-table/cell"
# require "terminal-table/core_ext"
# require "terminal-table/row"
# require "terminal-table/separator"
# require "terminal-table/style"
# require "terminal-table/table_helper"
# require "terminal-table/table"
# require "terminal-table/version"

$:.unshift File.dirname(__FILE__)
%w(version core_ext table cell row separator style table_helper).each do |file|
  require "terminal-table/#{file}"
end
