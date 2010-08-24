puts "LOADING registrar application"

require 'java'
require 'time' # Time::now.httpdate # TODO: put this in a helper ?

ContactBinding = Struct::new(:contact, :call_id, :cseq, :expires)
class ContactBinding
  def to_s
    "ContactBinding[#{contact.to_s}]: call_id: #{call_id}, cseq: #{cseq}, expires: #{expires}"
  end
end

registrations = {}

def canonicalTo(uri)
  "sip:#{uri.user}@#{uri.host.downcase}"
end

response "invite" do
end

invite /sip:(.*)@(.*)/ do
  puts "USER: #{$1}"
  puts "HOST: #{$2}"
  
  puts headers['User-Agent'].to_a.join ' '
  modify_header'User-Agent', /ph(one)/, 't\1s'
  puts headers['User-Agent'].to_a.join ' '
  
  proxy 'sip:toto@192.168.0.1'
end

register do  
  now = Time::now
  aor = canonicalTo(message.to.uri)
  puts "AOR: #{aor}"

  bindings = (registrations[aor] ||= [])
  
  wildcard = false
  contacts = address_headers[:Contact].map do |contact|
    wildcard = true if contact.wildcard?
    contact
  end
  if wildcard && contacts.size > 1
    send_response :bad_request, "Invalid wildcard" 
    return
  end
  cseq = header[:CSEQ].split(/ /).first.to_i
  if wildcard 
    # TODO
    puts "  WAS A WILDCARD"
    raise RuntimeError, "Not yet implemented"
  else
    contacts.each do |contact| 
      puts "  Handling contact: #{contact}"
      expires = contact.expires
      expires = message.expires if expires < 0
      if expires != 0
        expires = 300  if expires < 0     # default
        expires = 3600 if expires > 3600  # max expire
        if expires < 60 # min expires
          send_response :interval_too_brief, 'Min-Expires' => 60
          return
        end
      end
      binding = bindings.find { |binding| binding.contact == contact.uri }
      if binding
        if (message.call_id == binding.call_id && cseq < binding.cseq)
          send_response :server_internal_error, "Lower CSeq"
          return
        end
        if expires == 0
          puts "  DELETING BINDING for: #{contact.uri}"
          deleted_binding = bindings.delete_if { |binding| binding.contact == contact.uri }
        else
          binding.call_id = message.call_id
          binding.cseq = cseq
          binding.expires = now.to_i + expires 
          puts "  UPDATED BINDING: #{binding}"
        end
      elsif expires != 0
        binding = ContactBinding::new(contact.uri, message.call_id, cseq, expires) # TODO: allow prunning
        puts "  ADDED BINDING: #{binding}"
        bindings << binding
      end
    end
  end
  puts "  BINDINGS for #{aor} are #{bindings.map(&:contact).map(&:to_s).join(", ")}"
  send_response :ok, :Date  => now.httpdate do |response|
    bindings.each do |binding|
     # create_address binding.contact, :expires => (binding.expires - now TODO)
    end
  end    
end

#response do
  #response.addHeader("Handled-By", "Cipango-JRuby")
#end

puts "FINISHED loading registrar application"
