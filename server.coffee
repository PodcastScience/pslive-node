

require('coffee-script')
express = require('express')
routes = require('./routes')
user = require('./routes/user')
http = require('http')
https = require('https')
path = require('path')
md5 = require('MD5')
mu = require('mu2')
validator = require('validator')

app = express()

livedraw_iframe = ""

# functions
replaceURLWithHTMLLinks = (text) ->
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  return text.replace(exp,"<a href='$1' target='_blank'>$1</a>")

replaceSalaud = (text) ->
  exp=/salaud/ig
  retval=text.replace(exp,"salop\*")
  if (text!=retval)
    retval=retval+"<br><span style='font-weight:lighter;font-size:x-small;'>*Correction apportée selon la volonté du DictaTupe.</span>"
  return retval

        
  

  

#all environments
app.use require('connect-assets')()
console.log js('client')
app.set('port', process.env.PORT || 3000)
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon("/images/fav.png"));
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));

app.locals.css = css
app.locals.js = js

#development only
if ('development' == app.get('env'))
  app.use(express.errorHandler());


app.get('/', routes.index);
app.get('/h5', routes.indexh5);
app.get('/admin', routes.admin);
app.get('/users', user.list);
app.get '/messages', (req, res) ->
  res.send all_messages.map((message) -> "<b>#{message.user.username} :</b> #{message.message}").join("<br/>")
app.get '/noshary', (req, res) ->
  res.send "Pas de dessins ce soir :("

httpServer = http.createServer(app).listen(app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))
)

io = require('socket.io').listen(httpServer)

io.configure ->
  io.set("transports", ["xhr-polling"])
  io.set("polling duration", 10)
  io.set('close timeout', 20)
  # io.set('log colors',false)
  # io.set('log level',0)


users = new Object()
nb_conex = 0
all_messages = []
last_messages = []
history = 10
sharypicAPIKey = process.env.PSLIVE_SHARYPIC_APIKEY
#sharypicAPIKey = ''
admin_password = process.env.PSLIVE_ADMIN_PASSWORD
#admin_password = ""
episode = 'Bienvenue sur le balado qui fait aimer la science!'


#Fonction pour la gestion de SharyPic
getIframeStr = (jsonData) -> 
  return '<iframe width="640" height="480" scrolling="no" frameborder="0" src="http://www.sharypic.com/events/'+jsonData.uid+'/widget?collection=all&theme=dark&autoplay=true&share=true&scoped_to=all&timing=10000"><a href="https://www.sharypic.com/'+jsonData.uid+'/all" title="'+jsonData.description+'" >'+jsonData.description+'</a></iframe>'
  

    
createSharypicEvent = (name,libelle) ->
  console.log("Creation de l'event SharyPic : " + name)
  param=JSON.stringify({
    name: name,
    description: name+" - "+libelle,
    public: true,
    hashtag: "#"+name
  })

  headers = {
    'Content-Type': 'application/json',
    'Content-Length': param.length
  }

  options = {
    host: 'api.sharypic.com',
    port: 443,
    path: '/v1/user/events.json?api_key='+sharypicAPIKey,
    method: 'POST',
    form: param,
    headers:headers
  }

  req = https.request(options,(res) ->
    data=''
    res.on('data', (chunk) ->
        data += chunk
    )
    res.on('end',() ->
        console.log("Event SharyPic cree : " +  data)
        jsonData = JSON.parse data
        livedraw_iframe = getIframeStr(jsonData)
        io.sockets.emit('new-drawings',livedraw_iframe)
    )
  ).on('error', (e) ->  console.log("Got error: " + e.message))
  req.write(param);
  req.end();
#Fin des Fonctions pour la gestion de SharyPic









io.sockets.on 'connection', (socket) ->
  console.log "Nouvelle connexion... ("+io.sockets.clients().length+" sockets)"

  # mise a jour du conmpteur de connectes
  nb_conex += 1
  io.sockets.emit('update_compteur',nb_conex)

  # gestion des utilisateurs
  me = false  



  for key, value of users
    socket.emit('newuser',value)

  for message in last_messages
    socket.emit('nwmsg',message)
    console.log(socket.id)

  socket.emit('new-drawings',livedraw_iframe)
  socket.emit('new-title',episode)
  socket.on 'login', (user) ->
        
    try 
      validator.isEmail(user.mail)
    catch
      socket.emit('error',"Email invalide")

    try
      validator.isLength(user.username,3,30)
    catch
      socket.emit('error',"Le nom d'utilisateur doit être compris entre 3 et 30 lettres")

    try 
      validator.isEmail(user.mail)
      validator.isLength(user.username,3,30)

      # check if user already exist
      for key, existing_user of users
        if user.mail == existing_user.mail
          me = existing_user 
          console.log 'user already exist!'

      unless me
        me = user
  #      me.id = user.mail.replace('@','-').replace(/\./gi, "-")
        me.id = Date.now()
        me.avatar = 'https://gravatar.com/avatar/' + md5(user.mail) + '?s=40'
        users[me.id] = me
        io.sockets.emit('newuser',me)

      socket.emit('logged')




  socket.on 'disconnect', ->
    console.log(me.username+" s'est deconnecté...")
    nb_conex = nb_conex - 1    
    
    io.sockets.emit('update_compteur',nb_conex)
    console.log("nombre d'utilisateurs : "+nb_conex)
    console.log('me : '+me)
    unless me == false
      delete users[me.id]
      io.sockets.emit('disuser',me)


  # gestion des mesages
  socket.on 'nwmsg', (message) ->
    message.user = me
    date = new Date()

    message.message = replaceURLWithHTMLLinks(validator.escape(message.message))
    message.message = replaceSalaud(message.message)
    message.h = date.getHours()
    message.m = date.getMinutes()
    all_messages.push message
    last_messages.push message
    last_messages.shift() if (last_messages.length > history)

    io.sockets.emit('nwmsg',message)


  # Changement du titre et chargement de l'iframe
  socket.on 'change-title', (message) ->
    nomEvent='ps'+message.number
    if message.password == admin_password 
      options = {
        host: 'api.sharypic.com',
        port: 443,
        path: '/v1/user/events.json?api_key='+sharypicAPIKey
      }
      data=''
      req = https.get(options,(res) ->
        res.on('data',(d)->data+=d)
        res.on('end',getSharyEvents)
      ).on('error', (e) ->  console.log("Got error: " + e.message))

      getSharyEvents = () ->
        console.log("Sharypic : "+data)
        dateref=0
        jsonData = JSON.parse data
        bTrouve=false
        for key, value of jsonData
          console.log(value.name+'/'+nomEvent);
          if value.name==nomEvent & value.created_at>dateref
            livedraw_iframe = getIframeStr(value)
            io.sockets.emit('new-drawings',livedraw_iframe)
            bTrouve=true
            dateref=value.created_at
        if !bTrouve && message.createEvent
          createSharypicEvent(nomEvent,message.title)
        else
          io.sockets.emit('new-drawings',livedraw_iframe)
        
      episode= "<span class='number'> Episode #"+(message.number)+" - </span> "+message.title
      io.sockets.emit('new-title',episode)
  # test

  # socket.on 'test', ->
  # 	console.log(users)




