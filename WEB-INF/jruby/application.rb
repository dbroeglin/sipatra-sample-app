puts "LOADING registrar application"

require 'java'
SipServletResponse = javax.servlet.sip.SipServletResponse

registrations = {}

Binding = Struct::new(:contact, :call_id, :cseq, :expires)

def canonicalTo(uri)
  "sip:#{uri.user}@#{uri.host.downcase}"
end

def create_and_send_response(status, msg)
  request.createResponse(status, msg).send();
end

register do
  aor = canonicalTo(request.to.uri)
  puts "AOR: #{aor}"

  bindings = (registrations[aor] ||= [])
  
  wildcard = false
  contacts = address_headers[:Contact].map { |contact|
    wildcard = true if contact.wildcard?
    contact
  }
  if wildcard && contacts.size > 1
    create_and_send_response SipServletResponse.SC_BAD_REQUEST, "Invalid wildcard" 
    break
  end
  cseq = header[:CSEQ].split(/ /).first.to_i
  if wildcard 
    # TODO
    puts "  WAS WILDCARD"
  else
    puts "  WAS NOT WILDCARD"
    contacts.each do |contact| 
      puts "  Handling contact: #{contact}"
      expires = contact.expires
      expires = request.expires if expires < 0
      if expires != 0
        expires = 300  if expires < 0     # default
        expires = 3600 if expires > 3600  # max expire
        if expires < 60 # min expires
          response = request.createResponse(SipServletResponse.SC_INTERVAL_TOO_BRIEF)
          response.addHeader('Min-Expires', 60)
          response.send
          break
        end
      end
      binding = bindings.find { |binding| binding.contact == contact.uri }
      if binding
        if (request.call_id == binding.call_id && cseq < binding.cseq)
          create_and_send_response SipServletResponse.SC_SERVER_INTERNAL_ERROR, "Lower CSeq"
          break
        end
        if expires == 0
          puts "  DELETING BINDING for: #{contact.uri}"
          deleted_binding = bindings.delete_if { |binding| binding.contact == contact.uri }
        else
          binding.call_id = request.call_id
          binding.cseq = cseq
          binding.expires = expires # TODO: change this to allow prunning
          puts "  UPDATED BINDING: #{binding}"
        end
      elsif expires != 0
        binding = Binding::new(contact.uri, request.call_id, cseq, expires) # TODO: allow prunning
        puts "  ADDED BINDING: #{binding}"
        bindings << binding
      end
    end
  end
  puts bindings.join("\n")
  response = request.createResponse SipServletResponse.SC_OK
  response.addHeader('Date', "TODO")
    
  # TODO add Contact headers
    
  response.send
end

#response do
  #response.addHeader("Handled-By", "Cipango-JRuby")
#end

puts "FINISHED loading registrar application"
