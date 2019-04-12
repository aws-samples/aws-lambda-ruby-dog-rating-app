require 'json'
require 'rack'
require 'base64'

APP = Rack::Builder.parse_file('config.ru').first

def handler(event:,context:)
  $baseHost ||= event.fetch('headers', {}).fetch('Host', nil)
  # Check if the body is base64 encoded. If it is, try to decode it
  body = 
    if event['isBase64Encoded']
      Base64.decode64(event['body'])
    else
      event['body']
    end
  # Rack expects the querystring in plain text, not a hash
  querystring = Rack::Utils.build_query(event['queryStringParameters']) if event['queryStringParameters']
  # Environment required by Rack (http://www.rubydoc.info/github/rack/rack/file/SPEC)
  env = {
    'REQUEST_METHOD' => event['httpMethod'],
    'SCRIPT_NAME' => '',
    'PATH_INFO' => event['path'] || '',
    'QUERY_STRING' => querystring || '',
    'SERVER_NAME' => $baseHost,
    'SERVER_PORT' => 443,
    'CONTENT_TYPE' => event['headers']['content-type'],

    'rack.version' => Rack::VERSION,
    'rack.url_scheme' => 'https',
    'rack.input' => StringIO.new(body || ''),
    'rack.errors' => $stderr,
  }
  # Pass request headers to Rack if they are available
  unless event['headers'].nil?
    event['headers'].each { |key, value| env["HTTP_#{key}"] = value }
  end

  begin
    # Response from Rack must have status, headers and body
    status, headers, body = APP.call(env)

    # body is an array. We combine all the items to a single string
    body_content = ""
    body.each do |item|
      body_content += item.to_s
    end

    # We return the structure required by AWS API Gateway since we integrate with it
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
    response = {
      'statusCode' => status,
      'headers' => headers,
      'body' => body_content
    }
    if event['requestContext'].key?('elb')
      # Required if we use Application Load Balancer instead of API Gateway
      response['isBase64Encoded'] = false
    end
  rescue Exception => msg
    # If there is any exception, we return a 500 error with an error message
    response = {
      'statusCode' => 500,
      'body' => msg
    }
  end
  # By default, the response serializer will call #to_json for us
  response
end
