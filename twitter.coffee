oauth   = require('oauth')
events  = require('events')
util  = require("util")

url = {
  filter      : 'https://stream.twitter.com/1.1/statuses/filter.json'
  request_token   : 'https://api.twitter.com/oauth/request_token'  
  access_token  : 'https://api.twitter.com/oauth/access_token'
}


class Stream extends events.EventEmitter
  stream_imm=null
  constructor: (params) ->
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
      if params.track=='#' 
        console.log "hashtag invalide :",params
        return
      console.log "debut du stream Twitter avec le hashtag ",params
      if typeof params != 'object'
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
          data_length=0
          response.setEncoding 'utf8'
          response.on 'data', (data) ->
            if data == separator
              return
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
        response.on 'error', (error) ->this.emit 'close', error
        response.on 'end', () -> this.emit 'close', 'socket end'
        response.on 'close', () ->  request.abort()
      request.on 'error', (error) -> this.emit 'error', {type: 'request', data: error}
      request.end()

  stream : (params) ->
  	setTimeout (()->stream_imm params) , 10000




module.exports = Stream
