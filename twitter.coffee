oauth   = require('oauth')
events  = require('events')
util  = require("util")
querystring  = require("querystring")
server = process.env.PSLIVE_URL
url = {
  filter      : 'https://stream.twitter.com/1.1/statuses/filter.json'
  request_token   : 'https://api.twitter.com/oauth/request_token'  
  access_token  : 'https://api.twitter.com/oauth/access_token'
  userinfo  : 'https://api.twitter.com/1.1/account/verify_credentials.json'
}


class Stream extends events.EventEmitter
  stream_imm=null
  auth_tockens= null
  sockets= null
  constructor: (params) ->
    auth_tockens= []
    sockets= []
    super()
    return new Stream(params) if !(this instanceof Stream) 
    events.EventEmitter.call(this);
    @params = params;
    @oauth = new oauth.OAuth(
      url.request_token,
      url.access_token,
      @params.consumer_key,
      @params.consumer_secret,
      '1.0', 
      null, 
      'HMAC-SHA1', 
      null,
      {
        'Accept': '*/*',
        'Connection': 'close',
        'User-Agent': 'ps-live.js'
      }
    )
    stream_imm = (params) =>
      stream = this
      params.track = params.track
      if params.track=='#' 
        console.log "hashtag invalide :",params
        return
      console.log "debut du stream Twitter avec le hashtag ",params
      if typeof params != 'object'
        console.log "probleme de params",params
        params = {} 
      params.delimited = 'length'
      params.stall_warnings = 'true'
      request = this.oauth.post(
        url.filter,
        @params.access_token_key,
        @params.access_token_secret,
        params, 
        null
      )
      this.destroy = () -> request.abort()
      request.on 'response', (response) ->
        if response.statusCode > 200
          console.log "error",response.statusCode
          stream.emit 'error', {type: 'response', data: {code:response.statusCode}}
        else
          separator = '\r\n'
          buffer = ''
          data_length = 0
          response.setEncoding 'utf8'
          response.on 'data', (data) ->
            if data == separator && buffer == ''
              console.log "Twitter: heartbeat"
              stream.emit "heartbeat",data
            console.log "données recu"
            if (!buffer.length) 
              line_end_pos = data.indexOf(separator)
              data_length = parseInt(data.slice(0, line_end_pos))
              data = data.slice(line_end_pos+separator.length)
            buffer+=data
            if (buffer.length == data_length)
              parsed = false
              try
                retval = JSON.parse(buffer)   
                parsed = true;
              catch e
                console.log 'donnees ignorees '
              if (parsed) 
                stream.emit 'data', retval
                buffer=''
                data_length = 0 
            else
              console.log "donnees incomplete ("+buffer.length+"/"+data_length+")",buffer       
        response.on 'error', (error) ->
          console.log 'twitter error',Error
          stream.emit 'close', error
        response.on 'end', () -> 
          console.log 'twitter end'
          stream.emit 'close', 'socket end'
        response.on 'close', () -> 
          console.log 'twitter close'
          request.abort()
      request.on 'error', (error) -> this.emit 'error', {type: 'request', data: error}
      request.end()

  stream : (params) ->
    setTimeout (()->stream_imm params) , 10000

  get_auth : (socket,id_connexion) =>
    request = @oauth.post(
        url.request_token,
        @params.access_token_key,
        @params.access_token_secret,
        {oauth_callback:server+"twitter_auth/?id="+id_connexion}, 
        (e,data) =>
          if e
            console.log e
          else
            response = querystring.parse(data)
            if response.oauth_callback_confirmed == 'true'
              console.log "step1/response:",response
              sockets[id_connexion]=socket
              socket.emit 'openurl' , 'https://twitter.com/oauth/authenticate?oauth_token='+response.oauth_token

      )
  get_auth_step2 : (res,req) =>
    console.log "step2",req.query
    socket=sockets[req.query.id]
    request = @oauth.post(
        url.access_token,
        @params.access_token_key,
        @params.access_token_secret,
        {
          oauth_token:req.query.oauth_token,
          oauth_verifier:req.query.oauth_verifier
        }, 
        (e,data) =>
          if e
            console.log e
          else
            response = querystring.parse(data)
            console.log response

            auth_tockens[response.oauth_token] = response.oauth_token_secret
            socket.emit 'twitter_auth_ok',response.oauth_token
            res.redirect(server+'close')

      )
  get_auth_info : (key,cb) =>
    console.log 'twitter/ recuperation des infos utilisateurs',key
    request = @oauth.get(
        url.userinfo,
        key,
        auth_tockens[key] ,
        (e,data) =>
          if e
            console.log e
          else
            response = JSON.parse(data)
            console.log "response" ,response
            cb {
              username : response.name
              avatar : response.profile_image_url
              mail : response.screen_name+'@twitter'
            }
            #name/sceen_name/profile_image_url
            #console.log response
            #res.redirect('http://localhost:3001')

      )
  

module.exports = Stream
	