#!/usr/bin/ruby

require 'rubygems'
require 'rest_client'
require 'json'
require 'yaml'

class Api_Fetcher

	class Dns
		attr_accessor :record_id, :name, :type, :content, :ttl, :create_date

		def delete
		end

		def update
		end

		def save
		end
	end

	def initialize(api_url, api_username, api_token)
		@api_url = api_url
		@api_username = api_username
		@api_token = api_token
		login
	end

	def login
		response = RestClient.post "#{@api_url}api/login", {:username => @api_username, "api_token" => @api_token}.to_json, :content_type => :json, :accept => :json
		api_session_token = JSON.parse(response.body)
		@api_session_token = api_session_token["session_token"]		
	end

	def logout
	end	

	def request(uri, body)

	end

	def list_dns domain
		response = RestClient.get "#{@api_url}api/dns/list/#{domain}", { 
			:accept => :json,
			'Api-Session-Token' => @api_session_token
		}
		records = JSON.parse(response.body)
		records = records["records"]		
	end

	def update_dns record, my_ip
		response = RestClient.post("#{@api_url}api/dns/delete/#{record[:domain]}", { :record_id => record[:id]}.to_json, 'Api-Session-Token' => @api_session_token, :content_type => :json, :accept => :json)
		create_dns record, my_ip
	end

	def create_dns record, my_ip
		p "#{@api_url}api/dns/create/#{record[:domain]}"
		response = RestClient.post("#{@api_url}api/dns/create/#{record[:domain]}", { :hostname => record[:hostname], :type => 'A', :content => my_ip, :ttl => 300, :priority =>record[:priority]}.to_json, 'Api-Session-Token' => @api_session_token, :content_type => :json, :accept => :json)
		return JSON.parse response.body
	end
end



class Name
	def get_ip
		get_ip_cmd = 'curl ifconfig.me'
		my_ip = `#{get_ip_cmd}`		
		#my_ip = '76.102.255.45'
	end

	def initialize
		#@config = YAML::load_file("#{Dir.pwd}/name.yml")
		@config = YAML::load_file("#{File.dirname(File.expand_path(__FILE__))}/name.yml")
		@api = Api_Fetcher.new @config['api_url'], @config['api_username'], @config['api_token']
	end

	def sync
		while (true) do
			_sync
			sleep @config['interval']
		end
	end	

	@private
	def _sync
		my_ip = get_ip
		@config['domain'].each do |domain|
			records = @api.list_dns domain['name']
			
			puts "Found definition: #{domain['name']}. Start to process"
			domain["dns"].each do |dns|
				zone = (dns.nil?) ? domain['name']: "#{dns}.#{domain['name']}"
				puts "\n== Found Hostname: #{zone}."			
				existed = false
				records.each do |record|
					if (record["name"]==zone && record["type"]=="A")
						existed = true
						if (record["content"]==my_ip) 
							puts "====== IP is in sync: #{zone}"							
						else 
							puts "====== Update for: #{zone}"
							begin 
								result = @api.update_dns( {:domain => domain['name'], :id => record["id"], :hostname => dns}, my_ip) 	
								puts result.inspect		
							rescue Exception => e
								puts "Error when processing. Automatic to try again later"
							end
						end
					end
				end

				if (!existed)  
					puts "====== Create for: #{zone}"						
					result = @api.create_dns({:domain => domain['name'], :hostname => dns}, my_ip) 
					puts result.inspect
				end
			end
			puts "\n\n\n"
		end
	end
end

Name.new.sync