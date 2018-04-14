require 'rubygems' 
require 'mongo'
require 'json'
require 'salesforce_bulk'
# require 'set'
# require 'savon'
# require 'pp'
require 'net/http'
require 'date'
require 'openssl'
require 'base64'
include Mongo


class Api::Services::ServicesController < Api::Services::ApiController
	def get_supported_integration		
		@application_details = Connectordata.first.application_details
	
		render json: @application_details
	end

	def get_mapping
		@mapping = Connectordata.last.mapping

		render json: @mapping
	end

	def getTokenDetails(token)
		puts "===getToken==="
		puts "=token==#{token}"
		# if Rails.env == "development"
		# 	client = Mongo::Client.new([ '192.168.1.132:27017' ], :database => 'paragyte_connector_app_development')
		# else
			mongohq_url = ENV['MONGOHQ_URL']
			client = Mongo::Client.new(mongohq_url);
		# end

		org_id = token.split(//).last(15).join("").to_s
		date_time_number = token[0...-15]
		token_expiry_details = client[:token_expiry_details].find({})

		puts "===org_id==#{org_id}"
		puts "===date_time_number==#{date_time_number}"
		puts "===token_expiry_datetails==#{token_expiry_details}"

		puts "===token_expiry_details==#{token_expiry_details.first}"
		# puts "===token_expiry_details org_id==#{token_expiry_details.first[org_id]}"
		# puts "===token_expiry_details token_expiry_number==#{token_expiry_details.first[org_id]["token_expiry_number"]}"
		if !token_expiry_details.first.nil?
			token_expiry_details.each do |token_details|
				if !token_details[org_id].nil?
					puts "==in if condition token_details=="
					@exist_token_expiry_number = token_details[org_id]["token_expiry_number"].to_i
				end
			end
		end

		puts "==exist_token_expiry_number====#{@exist_token_expiry_number}"
		# exist_org_details = token_expiry_details[org_id]
		# exist_token_expiry_number = exist_org_details["token_expiry_number"]
		if @exist_token_expiry_number.nil?
			isValidToken = false
		elsif @exist_token_expiry_number > date_time_number.to_i 
			isValidToken = true
		else
			isValidToken = false
		end
		
		return client, isValidToken
	end

	def get_supported_integration2	
		begin
			key  = JSON.parse(response.request.headers["Token"]) 		
			# key_token = key["Token"]	
			client, isValidToken = getTokenDetails(key["Token"]	)	

			if isValidToken
				db = client.database		
				@application_details = db[:application_details].find({})	
				render json: @application_details	
			else
				render json: "Token is Expired"
			end
		rescue Exception => e
			render json: "False"
		end
 		
	end
	
	def get_mapping3
		# if Rails.env == "development"
		# 	client = Mongo::Client.new([ '192.168.1.132:27017' ], :database => 'paragyte_connector_app_development')
		# else
			# mongohq_url = ENV['MONGOHQ_URL']
			# client = Mongo::Client.new(mongohq_url);
		# end
		begin
			key  = JSON.parse(response.request.headers["Token"]) 		
			client, isValidToken = getTokenDetails(key["Token"]	)	
			@org_id = key["Token"].split(//).last(15).join("").to_s
			
			# @org_id = "28000000eZIaEAM1"
			# isValidToken = true
			@isCustomMapping = false
			if isValidToken
				client[:custom_mapping].find({}).each do |org|				
					if @org_id == org["Mapping"].first["org_id"] 
						@isCustomMapping = true
						@mapping = org
						puts "==org_id=="
					end
				end
				if !@isCustomMapping 
					db = client.database
					@mapping = db[:mapping2].find({})	
				end
				render json: @mapping	
			else
				render json: "Token is Expired"
			end
		rescue Exception => e
			 render json: "False"
		end
		
	end

	def render_routing_error
		render json: "Invalid URL"
	end

	def save_mapping
	  puts "===save mapping ==="	
	  
		begin
			key  = JSON.parse(response.request.headers["Token"]) 		
			mongo_client, isValidToken = getTokenDetails(key["Token"]	)	
			
			if isValidToken
				isInvalidParams = ["|",";","timeout","sleep","start-sleep","EXEC","cmd","--"," OR "," AND "," or "," and ","'='"].any? {|s| params["key"].include? s}
				if !isInvalidParams
					isInvalidParams = ["|",";","timeout","sleep","start-sleep","EXEC","cmd","--"," OR "," AND "," or "," and ","'='"].any? {|s| params["JSON"].include? s}
				end
				if !isInvalidParams
					algo = 'AES-128-CBC'
					encrypt_key = Base64.decode64(params["key"])
					cipher = OpenSSL::Cipher.new(algo)
					cipher.decrypt()
					cipher.key = encrypt_key
					tempkey = Base64.decode64(params["JSON"])
					crypt = cipher.update(tempkey)
					crypt << cipher.final()
					data = crypt[16..-1]
					json_data = JSON.parse(data)
					# data = params["Mapping"].to_s 
				
					isInvalidJson = ["|",";","timeout","sleep","start-sleep","EXEC","cmd","--"," OR "," AND "," or "," and ","'='"].any? {|s| data.include? s}

					if !isInvalidJson && data.count("&") <= 2 #&& params["Mapping"].first["JsonDataSize"] == request.raw_post.length.to_s
						json_data["Mapping"].each do |mappingdoc|
							@org_id = mappingdoc["Org_Id"] 			
						end

					# mongohq_url = ENV['MONGOHQ_URL']
					# mongo_client = Mongo::Client.new(mongohq_url);
					
						mongo_client[:updated_mapping].find({}).each do |org|
							@exist_org_id = org["Org_Id"] 										
							if @exist_org_id == @org_id
								puts "=== if==="
								mongo_client[:updated_mapping].find(:_id => org["_id"]).delete_one	
							end												
						end			
						mongo_client[:updated_mapping].insert_one(json_data["Mapping"].first)				
						# render json: 'Success'
						@result = "Success"
					else
						@result = "Invalid Json"
					end	
				else
					@result = "Invalid Json"
				end
			else
				@result = "Token is Expired"
				# render json: "Token is Expired"
			end
		rescue Exception => e
			@result = "False"
			# render json: "Token is Expired"
		end
	puts "====="
	puts @result
		render json: @result
	end


	def validate_credentials
		begin
			@credential_status = Hash.new 
			key  = JSON.parse(response.request.headers["Token"]) 		
			client, isValidToken = getTokenDetails(key["Token"]	)	

			if isValidToken

				sfdc_username = params["Credentials"].first["Username"] 
				sfdc_password_securitytoken = params["Credentials"].first["Pass"] + params["Credentials"].first["SecurityToken"]

				erp_username = params["Credentials"].last["Username"]
				erp_password = params["Credentials"].last["Pass"]
				erp_dataserver = params["Credentials"].last["Dataserver"]
				erp_host = params["Credentials"].last["Host"]			 

				

				# begin			
					salesforceclient = SalesforceBulk::Api.new("#{sfdc_username}", "#{sfdc_password_securitytoken}")
				# rescue 
				# end

				if salesforceclient.nil? 
					@credential_status["salesforce"] = false
				else
					@credential_status["salesforce"] = true
				end

				# if erp_username == 'pplnav' && erp_password == '123' && erp_dataserver == 'dc' && erp_host == '12.0.4100.1'
				# 	@credential_status["erp"] = true
				# else
				# 	@credential_status["erp"] = false
				# end
				
				if erp_username.casecmp("pplnav") == 0 && erp_password.casecmp("123") == 0 && erp_dataserver.casecmp("dc") == 0 #&& erp_host == '12.0.4100.1'
					@credential_status["erp"] = true
				else
					@credential_status["erp"] = false
				end	
			
				# begin
				#   erp_client = TinyTds::Client.new username: "#{erp_username}", password: "#{erp_password}", dataserver: "#{erp_dataserver}" #, host: "#{erp_host}"
				# rescue Exception => e
				# 	puts "==#{e.message}=="
				#   retry if e.message.include?("Unable to connect: Adaptive Server is unavailable or does not exist")
				# end
		
				# puts "==erp client=="
				# puts erp_client
				# if erp_client.nil? 
				# 	@credential_status["erp"] = false
				# else
				# 	@credential_status["erp"] = true
				# end

				render json: @credential_status, :status => :ok	
			else
				render json: "Token is Expired"
			end		
		rescue Exception => e
			if @credential_status.empty?
				@credential_status["salesforce"] = false
				@credential_status["erp"] = false
			elsif @credential_status["salesforce"] == true
				@credential_status["erp"] = false		
			end
			render json: @credential_status
		end


		
	end

	def delete_mapping
		puts "=====params==="
		puts params

	  begin
	  	key  = JSON.parse(response.request.headers["Token"]) 		
			mongo_client, isValidToken = getTokenDetails(key["Token"]	)	

			if isValidToken
				@exist_org_id = params["Organization"]
				mongo_client[:updated_mapping].find({}).each do |org|
					# org["Mapping"].each do |mappingdoc|
						@Org_Id = org["Org_Id"] 						
						if @exist_org_id == @Org_Id
							mongo_client[:updated_mapping].find(:_id => org["_id"]).delete_one	
						end
					# end
				end
				render json: 'Success'
			else
				render json: "Token is Expired"
			end	
	  rescue Exception => e
	  	render json: "False"
	  end
		
	end

	def start_sync
		begin
			puts "==start_sync=="
		
			puts "==first"
			puts response.request.headers["Token"]
			puts "==second=="
			puts JSON.parse(response.request.headers["Token"]) 	
			# if Rails.env == "development"
			# 	key  = response.request.headers["Token"] 		
			# else
				key_token  = JSON.parse(response.request.headers["Token"]) 	
				key = key_token["Token"]
			# end
			
			mongo_client, isValidToken = getTokenDetails(key)	
			org_id = key.split(//).last(15).join("").to_s

			if isValidToken
				# ConnectorJob.perform_later(org_id)
				render json: "Success"
			else
				render json: "Token is Expired"
			end
		rescue Exception => e
			render json: "False"
		end
		
	end

	def set_token		
		puts "==set_token=="	
		begin
			@isExistId = false
			key  = JSON.parse(response.request.headers["Token"])
			key_token = key["Token"]
			puts "key_token===#{key_token}"
			puts "key_token class=== #{key_token.class}"
		
			org_id = key_token.split(//).last(15).join("").to_s
			date_time_number = key_token[0...-15]

			sec = (date_time_number.to_f / 1000).to_s
			tokenDateTime = DateTime.strptime(sec, '%s')
			token_expiry_date = tokenDateTime + 5.day
			puts "==token_expiry_date==#{token_expiry_date}"
			token_expiry_number = token_expiry_date.strftime('%Q')
			puts "==token_expiry_number= #{token_expiry_number}"	 
			
			mongohq_url = ENV['MONGOHQ_URL']		
			mongo_client = Mongo::Client.new(mongohq_url);	
			token_expiry_details = mongo_client[:token_expiry_details]
			puts "==new org_id==#{org_id}"
			if !token_expiry_details.find({}).first.nil?
				token_expiry_details.find({}).each do |data|
					 puts "==in look ==#{data[org_id]}"
					if !data[org_id].nil?
						puts "===in if condition=="
						@isExistId = true
					end
				end
			end
			puts "===isExistId===#{@isExistId}"
			if !@isExistId
				result = token_expiry_details.insert_one({"#{org_id}": {org_id: "#{org_id}", token_expiry_number: "#{token_expiry_number}"}})	
			end
			if @isExistId
				render json: 'Token for this organization is already exist'
			else
				render json: 'Success'
			end
		rescue Exception => e
			render json: 'False'
		end
		
	end

	def get_logs
		puts "==params=="
		puts params
		# binding.pry
		# Parameters: {"Organization"=>"00D28000000eZIa-AX-2012-Database", "Record Id"=>"a022800000FzlRLAAZ", }
		key_token  = JSON.parse(response.request.headers["Token"]) 	
		key = key_token["Token"]
		
		mongo_client, isValidToken = getTokenDetails(key)	
		org_id = key.split(//).last(15).join("").to_s
		record_id = params["Record Id"]

		if isValidToken
			@log_array = Array.new
			# @logs_details = mongo_client[:Logs].find({})
			mongo_client[:Logs].find({}).each do |logs|
				if logs["organizationId"] == org_id && logs["recordId"] == record_id #&& logs["SchedulingStartTime"].split(" ").first == Date.today.to_s
					@log_array.push(logs)
				end
			end
			
			if @log_array.empty?
				render json: "No log record exist"
			else
				render json: @log_array
			end
			
		else
			render json: "Token is Expired"
		end
	end
	
	def send_email
		puts "===send_email=="
		# email = "kapilchothe@gmail.com"
		email = "kchothe@paragyte.com"
		mongohq_url = ENV['MONGOHQ_URL']
		client = Mongo::Client.new(mongohq_url);
		# binding.pry
		@data = client[:Logs].find({})#.first



		# binding.pry
		 Usermailer.welcome_email(email,@data).deliver_now
		render json: "Success"
	end

	def get_every_day_sync_details
	 	mongohq_url = ENV['MONGOHQ_URL']
		client = Mongo::Client.new(mongohq_url);
		@data = client[:Logs].find({})
		@sync_details = Hash.new
		objectRecordLogs = Hash.new
		
		@organization_details = {}
		@organization_id_set = Set.new
		@data.each do |data|
			@organization_id_set << data["organizationId"]
	  end		

	  @organization_id_set.each do |id|
	  	@sync_count = 0
	  	@data.each do |data|
	  		if id == data["organizationId"]
	  			objectLogs = Array.new
	  			@sync_count = @sync_count + 1
	  			if @sync_details[id].nil?
	  				data["OBJECTS"].each do |obj|
		  				objectRecordLogs = get_object_record(obj.first.first,obj.first.last)
		  				objectLogs.push(objectRecordLogs) if !objectRecordLogs.nil?
		  			end
		  			@sync_details[id] = {:ApplicationName => data["ApplicationName"],:SyncCount => @sync_count,:SourceName => data["SourceName"], :OBJECTS => objectLogs}
		  			# binding.pry
		  		elsif !@sync_details[id].nil?
		  			objectLogs = Array.new
		  			puts "===elseif=="
		  			data["OBJECTS"].each do |obj|
		  				objectRecordLogs = get_object_record_calculated(obj.first.first,obj.first.last,@sync_details[id])
		  				objectLogs.push(objectRecordLogs) if !objectRecordLogs.nil?
		  			end	
		  			@sync_details[id] = {:ApplicationName => data["ApplicationName"],:SyncCount => @sync_count,:SourceName => data["SourceName"], :OBJECTS => objectLogs}	
	  			end	  			
	  		end	  		
	  	end	
	  	email = "kchothe@paragyte.com"
	  	Usermailer.daily_sync_details(email,@sync_details[id]).deliver_now
	  end
		
		render json: "Success"
	end

	def get_object_record(object_name,new_record)
		objectRecordLogs = Hash.new
		objectRecordLogs[object_name] = {:MappingObj => new_record["MappingObj"],:InsertCount => new_record["InsertCount"], :UpdateCount => new_record["UpdateCount"], :ErrorCount => new_record["ErrorCount"]}
		return objectRecordLogs
	end

	def get_object_record_calculated(object_name,new_record,sync_details)
		objectRecordLogs = Hash.new
		sync_details[:OBJECTS].each do |record|
					# binding.pry
			if object_name == record.first.first
				insertCount = new_record["InsertCount"].to_i + record.first.last[:InsertCount].to_i
				updateCount = new_record["UpdateCount"].to_i + record.first.last[:UpdateCount].to_i
				errorCount = new_record["ErrorCount"].to_i + record.first.last[:ErrorCount].to_i
				# binding.pry
				objectRecordLogs[object_name] = {:MappingObj => record.first.last[:MappingObj],:InsertCount => insertCount,:UpdateCount => updateCount, :ErrorCount => errorCount}		
			end
		end
		
		return objectRecordLogs
	end
end 


