# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Logstash cLog Filter
# This filter is for cLog.
#
class LogStash::Filters::Clog < LogStash::Filters::Base

  # Usage:
  #
  # filter {
  #   rest {
  #     url => "http://example.com"
  #	header => {
  #		'key1' => 'value1'
  #		'key2' => 'value2'
  #	}
  #   }
  # }
  #
  
  config_name "clog"
  
  # Replace the message with this value.
  config :url, :validate => :string, :required => true
  config :header, :validate => :hash, :default => {  }

  public
  def register
    require "json"
    require "rest_client"
    require "openssl"
    require "base64"
    require_relative "EnvelopeEncryption"
  end # def register

  public
  def filter(event)
    return unless filter?(event)
	
	response = RestClient.get @url, @header
	parsed = JSON.parse(response)
	pubkey = parsed['pubKey']
	
	pubkey = OpenSSL::PKey::RSA.new Base64.decode64(pubkey)
	ee = EnvelopeEncryption.new
	eventinjson = JSON.generate(event)
	puts "EventInJson: "+eventinjson
	ciphertext, iv, encrypted_session_key = ee.encrypt(eventinjson, pubkey)
	
	eventhash = event.to_hash	
	eventhash.each do |key, value|
		event.remove(key)
	end
	event['_id'] = parsed['id']	
	event['ciphertext'] = Base64.strict_encode64(ciphertext)
	event['iv'] = Base64.strict_encode64(iv)
	event['encrypted_session_key'] = Base64.strict_encode64(encrypted_session_key)

	
    filter_matched(event)    
  end # def filter
  
end # class LogStash::Filters::Clog

