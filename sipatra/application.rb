invite /^sip:.*/ do
  puts "REQUEST: #{message.method} #{message.requestURI}"
  proxy
end

request do
 puts "REQUEST: #{message.method} #{message.requestURI}"
end

response do
 puts "RESPONSE: #{message.status} #{message.request.requestURI}"
end