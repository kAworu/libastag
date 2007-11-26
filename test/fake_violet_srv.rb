#!/usr/bin/ruby --debug


require 'webrick'
include WEBrick


ACTION = {
  :good => [
    %{},
    %{<message>LINKPREVIEW</message><comment>XXXX</comment>},
    %{<listfriend nb="1"/><friend name="toto"/>},
    %{<listreceivedmsg nb="1"/><msg from="toto" title="my message" date="today 11:59" url="broad/001/948.mp3"/>},
    %{<timezone>(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London</timezone>},
    %{<signature>XXXXX</signature>},
    %{<blacklist nb="1"/><pseudo name="toto"/>},
    %{<rabbitSleep>YES</rabbitSleep>},
    %{<rabbitVersion>V1</rabbitVersion>},
    %{<voiceListTTS nb="2"/><voice lang="fr" command="claire22k"/><voice lang="de" command="helga22k"/>},
    %{<rabbitName>nabmaster</rabbitName>},
    %{<langListUser nb="4"/><myLang lang="fr"/><myLang lang="us"/><myLang lang="uk"/><myLang lang="de"/>} ,
    %{<message>LINKPREVIEW</message><comment>XXXX</comment>},
    %{<message>COMMANDSEND</message><comment>You rabbit will change status</comment>},
    %{<message>COMMANDSEND</message><comment>You rabbit will change status</comment>}
  ]
  :bad  => [
    %{},
    %{},
    %{},
    %{},
    %{},
    %{},
  %{},
  %{},
  %{},
  %{},
  %{},
  %{},
  %{<?xml version="1.0" encoding="UTF-8"?><rsp><message>MESSAGENOTSEND</message><comment>Your idmessage is not correct or is private</comment></rsp>},
  %{<?xml version="1.0" encoding="UTF-8"?><rsp><message>MESSAGENOTSEND</message><comment>Your idmessage is not correct or is private</comment></rsp>},
]
}

class VioletApiServelet < HTTPServlet::AbstractServlet
def do_GET(req, res)
  res['Content-Type'] = "text/plain"

  # getting options.
  opts = parse_opts(req)
  debug opts.inspect
  next_rsp = (opts[:srvcmd] == "next_is_bad" ? :bad : :good)

  if opts[:action]
    rsp = ACTION[next_rsp][opts[:action]]
  end

  res.body = <<-EOF
  <?xml version="1.0" encoding="UTF-8"?>
      <rsp>
        #{rsp}
      </rsp>
    EOF
  end


  private

  def debug msg
    puts "\033[31;01mDEBUG:\033[00m #{msg}" if $DEBUG
  end

  def parse_opts(req)
    req.unparsed_uri.split(/&|\?/).inject(Hash.new) { |h,opt| if opt =~ /(.+)=(.+)/ then h[$1.to_sym] = $2 end; h }
  end
end



s = HTTPServer.new(
  :Port            => 3000,
  :charset         => "UTF-8"
)

s.mount("/api.jsp",         VioletApiServelet)
s.mount("/api_stream.jsp",  VioletApiServelet)

trap("INT") { s.shutdown }
s.start

