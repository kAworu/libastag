#!/usr/bin/ruby


module FakeVioletSrv
  require 'webrick'
  include WEBrick

  # used to check serial
  SERIAL_MATCHER = /^[0-9A-F]+$/i
  # used to check token
  TOKEN_MATCHER  = /^[0-9]+$/

  # standard responses
  STDRSPs = {
    :NABCASTSENT        => '<message>NABCASTSENT</message><comment>Your nabcast has been sent</comment>',
    :MESSAGESENT        => '<message>MESSAGESENT</message><comment>Your message has been sent</comment>',
    :TTSSENT            => '<message>TTSSENT</message><comment>Your text has been sent</comment>',
    :CHORSENT           => '<message>CHORSENT</message><comment>Your chor has been sent</comment>',
    :EARPOSITIONSENT    => '<message>EARPOSITIONSENT</message><comment>Your ears command has been sent</comment>',
    :POSITIONEAR        => '<message>POSITIONEAR</message><leftposition>8</leftposition><rightposition>10</rightposition>',
    :WEBRADIOSENT       => '<message>WEBRADIOSENT</message><comment>Your webradio has been sent</comment>'
  }

  # errors messages list
  ERRORS = {
    :ABUSESENDING           => '<message>ABUSESENDING</message><comment>Too much message sending,try later</comment>',
    :NOGOODTOKENORSERIAL    => '<message>NOGOODTOKENORSERIAL</message><comment>Your token or serial number are not correct !</comment>',
    :MESSAGENOTSENT         => '<message>MESSAGENOTSENT</message><comment>Your message could not be sent</comment>',
    :NABCASTNOTSENT         => '<message>NABCASTNOTSENT</message><comment>Your idmessage is private</comment>',
    :TTSNOTSENT             => '<message>TTSNOTSENT</message> <comment>Your text could not be sent</comment>',
    :CHORNOTSENT            => '<message>CHORNOTSENT</message><comment>Your chor could not be sent (bad chor)</comment>',
    :EARPOSITIONNOTSENT     => '<message>EARPOSITIONNOTSENT</message><comment>Your ears command could not be sent</comment>',
    :WEBRADIONOTSENT        => '<message>WEBRADIONOTSENT</message><comment>Your webradio could not be sent</comment>',
    :NOCORRECTPARAMETERS    => '<message>NOCORRECTPARAMETERS</message><comment>Please check urlList parameter !</comment>',
    :NOTV2RABBIT            => '<message>NOTV2RABBIT</message><comment>V2 rabbit can use this action</comment>'
  }

  # action list
  ACTIONS = [
      '', # action API is 1-based.
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
      '<message>COMMANDSENT</message><comment>You rabbit will change status</comment>',
      '<message>COMMANDSENT</message><comment>You rabbit will change status</comment>'
  ]

  class VioletApiServelet < HTTPServlet::AbstractServlet
    def do_GET(req, res)
      res['content-type'] = 'text/plain'

      # getting options.
      opts = parse_opts(req)

      if @next
        rsp     = @next
        @next   = nil
      else
        if opts[:sn] !~ SERIAL_MATCHER or opts[:token] !~ TOKEN_MATCHER
          rsp = ERRORS[:NOGOODTOKENORSERIAL]
        elsif opts[:action]
          rsp = ACTIONS[opts[:action].to_i]
        elsif opts[:ears] == 'ok'
          rsp = STDRSPs[:POSITIONEAR]
        end
      end

      res.body = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
          <rsp>
            #{rsp}
          </rsp>
      EOF
    end

    # Used by our testsuit.
    def do_POST(req, res)
      res['content-type'] = 'text/plain'

      # getting options.
      opts = parse_opts(req)

      @next = case opts[:gimme]
              when 'ACTION' then ACTIONS[opts[:no].to_i]
              when 'ERROR'  then ERRORS[opts[:type].to_sym]
              when 'STDRSP' then STDRSPs[opts[:type].to_sym]
              else rsp = 'sorry'
              end

      rsp ||= 'ok'

      res.body = rsp
    end

    private

    def debug msg
      puts "\e[31;01mDEBUG:\e[00m #{msg}" if $DEBUG
    end

    def parse_opts(req)
      # I swear I can do worst, so don't be affraid.
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

