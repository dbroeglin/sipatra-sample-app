puts "LOADING registrar application"

bindings = {}

invite 'sip:standard@.*' do
    proxy "sip:0970757075@#{request.getRequestURI.getHost}"
end

register do
    puts "  VIA    : '#{headers[:Via].join(", ")}'"
    puts "  CONTACT: '#{header['Contact']}'"
    proxy
end


  #response do
    #response.addHeader("Handled-By", "Cipango-Groovy")
  #end

puts "FINISHED loading registrar application"
