require 'rubygems' 
require 'mongo'
require 'salesforce_bulk_api'
require 'net/http'
require 'set'
require 'json'
require 'savon'
require 'pp'
include Mongo

class ConnectorJob # This is not an Active Job job, but pretty legal Crono job.
  def perform #(*args)
  	puts "===in perform===="  	
  end
end