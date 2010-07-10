puts "LOADING registrar application"

invite 'sip:standard@.*' do
    proxy "sip:0123456789@#{request.getRequestURI.getHost}"
end

register do
    puts "  VIA    : '#{headers[:Via].join(", ")}'"
    puts "  CONTACT: '#{header['Contact']}'"
    proxy
end

#response do
  #response.addHeader("Handled-By", "Cipango-JRuby")
#end

puts "FINISHED loading registrar application"
