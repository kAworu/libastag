#!/usr/bin/ruby


module FakeVioletSrv
  require 'webrick'
  include WEBrick

  # used to check serial
  SERIAL_MATCHER = /^[0-9A-F]+$/i
  # used to check token
  TOKEN_MATCHER  = /^[0-9]+$/

  # errors messages list
  ERRORS = {
    :WrongSerialOrToken => '<message>NOGOODTOKENORSERIAL</message><comment>Your token or serial number are not correct !</comment>'
  }

  # action list
  ACTIONS = [
      '', # array index begin to 0, but our action API begin to 1
      '<message>LINKPREVIEW</message><comment>XXXX</comment>',
      '<listfriend nb="1"/><friend name="toto"/>',
      '<listreceivedmsg nb="1"/><msg from="toto" title="my message" date="today 11:59" url="broad/001/948.mp3"/>',
      '<timezone>(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London</timezone>',
      '<signature>XXXXX</signature>',
      '<blacklist nb="1"/><pseudo name="toto"/>',
      '<rabbitSleep>YES</rabbitSleep>',
      '<rabbitVersion>V1</rabbitVersion>',
      '<voiceListTTS nb="2"/><voice lang="fr" command="claire22k"/><voice lang="de" command="helga22k"/>',
      '<rabbitName>nabmaster</rabbitName>',
      '<langListUser nb="4"/><myLang lang="fr"/><myLang lang="us"/><myLang lang="uk"/><myLang lang="de"/>' ,
      '<message>LINKPREVIEW</message><comment>XXXX</comment>',
      '<message>COMMANDSEND</message><comment>You rabbit will change status</comment>',
      '<message>COMMANDSEND</message><comment>You rabbit will change status</comment>'
  ]

  class VioletApiServelet < HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = 'text/plain'

    # getting options.
    opts = parse_opts(req)

    if opts[:sn] !~ SERIAL_MATCHER or opts[:token] !~ TOKEN_MATCHER
      rsp = ERRORS[:WrongSerialOrToken]
    elsif opts[:action]
      rsp = ACTIONS[opts[:action].to_i]
    elsif opts[:ears] == 'ok'
      rsp = '<message>POSITIONEAR</message><leftposition>8</leftposition><rightposition>10</rightposition>'
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



  def FakeVioletSrv.start(port=3_000, logfile=false)
    if logfile
      log = File.open(logfile, 'w')
      $stderr = log
    end

    s = HTTPServer.new(
      :Port            => port,
      :charset         => 'UTF-8'
    )

    s.mount('/api.jsp',         VioletApiServelet)
    s.mount('/api_stream.jsp',  VioletApiServelet)

    trap('INT') { s.shutdown }
    s.start
  end
end


FakeVioletSrv.start if $0 == __FILE__

