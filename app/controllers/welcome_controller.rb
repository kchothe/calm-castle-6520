class WelcomeController < ApplicationController
	def render_routing_error
		render json: "Invalid url"
	end
end
