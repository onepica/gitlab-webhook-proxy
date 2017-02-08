require 'sinatra'
set :port, 8088
# set :server, :thin
connections = []
get '/' do
  logger = Logger.new(__dir__ + '/requests.log')
  logger.debug('This is GET to root')
  'No such page.'
end
get '/inbound' do
  logger = Logger.new(__dir__ + '/requests.log')
  logger.debug('This is GET')
  'Only POST request are allowed.'
end
post '/inbound/?:type?' do |param|
  request.body.rewind  # in case someone already read it
  # JSON.parse
  data = request.body.read

  logger = Logger.new(__dir__ + '/requests.log')
  logger.debug('POST data')
  logger.debug(param)
  logger.debug(params)
  logger.debug(data)

  # acknowledge
  'message received'
end
