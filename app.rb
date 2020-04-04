#!/usr/bin/env ruby

require 'sinatra'
require 'json'

set :port, 8080
set :bind, '0.0.0.0'

def object_one
  {
    name: 'objectone'
  }
end

def object_two
  {
    name: 'objecttwo'
  }
end

def object_array
  [object_one, object_two]
end

def object(id)
  id.to_s == '1' \
    ? object_one \
    : object_two
end

get '/health' do
  [200, {}, "Healthy"]
end

get '/health.html' do
  [200, {}, "Healthy"]
end

get '/healthz' do
  [200, {}, "Healthy"]
end

get '/objects' do
  [200, {}, object_array.to_json]
end

get '/objects/:id' do
  [200, {}, object(params['id']).to_json]
end

post '/objects' do
  [201, {}, object(params['id']).to_json]
end

put '/objects/:id' do
  [200, {}, object(params['id']).to_json]
end

delete '/objects/:id' do
  [202, {}, object(params['id']).to_json]
end

# Now use 'echo-server' for other routes
def response_with_full_url(request)
  "#{request.ip} #{request.request_method} #{request.url} - : #{request.params}\n"
end

# request.fullpath    # => '/hello-world?foo=bar'
def response_with_full_path(request)
  "#{request.ip} #{request.request_method} #{request.fullpath} - : #{request.params}\n"
end

# request.path_info   # => '/hello-world'
def response_with_path_info(request)
  request.each_header do |header|
    logger.info "Header '#{header}'"
  end
  "#{request.ip} #{request.request_method} #{request.path_info} - : #{request.params}\n"
end

%w[get head post put delete options patch].each do |method|
  send method, '/*' do
    response_with_path_info(request)
  end
end
