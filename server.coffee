

require('coffee-script')
express     = require('express')
routes      = require('./routes')
user        = require('./routes/user')
http        = require('http')
https       = require('https')
path        = require('path')
md5         = require('MD5')
mu          = require('mu2')
validator   = require('validator')



app         = express()
redis       = require("redis").createClient()





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

        
  
pad2 = (val) ->
  if (val<10)
    return  '0'+val
  else
    return val
  

#all environments
app.use require('connect-assets')()
console.log js('client')
app.set('port', process.env.PORT || 3000)
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')
app.use(express.favicon("/images/fav.png"))
app.use(express.logger('dev'))
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(app.router)
app.use(express.static(path.join(__dirname, 'public')))

app.locals.css = css
app.locals.js = js

#development only
if ('development' == app.get('env'))
  app.use(express.errorHandler())


app.get('/', routes.index)
app.get('/admin', routes.admin)
app.get('/users', user.list)
app.get '/messages', (req, res) ->
  redis.lrange('all_messages', 0, -1, (error, items) ->
    res.send items.map((message) -> "<b>#{JSON.parse(message).user.username}:</b> #{JSON.parse(message).message}").join("<br/>")
  )
app.get '/noshary', (req, res) ->
  res.send "Pas de dessins ce soir :("
app.get '/timestamp', (req, res) ->
  redis.lrange('all_messages', 0, -1, (error, items) ->
    res.send items.map((message) -> 
      "<b>#{JSON.parse(message).user.username}</b> [#{JSON.parse(message).ts}]: #{JSON.parse(message).message}").join("<br/>")
  )

httpServer = http.createServer(app).listen(app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))
)


io = require('socket.io').listen(httpServer)

io.configure ->
  io.set("transports", ['websocket','flashsocket','htmlfile','xhr-polling','jsonp-polling'])
  #io.set("polling duration", 100)
  #io.set('close timeout', 200)
  io.set('heartbeat timeout', 200)
  # io.set('log colors',false)
  io.set('log level',0)



#fonction pour compter (.length ne marche pas.... a voir)
compte = (tab)->
  cpt=0
  for key,elt of tab
    cpt=cpt+1
  return cpt


suppressionListeMessages = () ->
  redis.llen('all_messages',(error,count)->
    if(count>0)
      redis.lpop('all_messages')
      suppressionListeMessages()
  )
  

suppressionConnexions = () ->
  redis.scard('liste_connex',(error,count)->
    if(count>0)
      redis.spop('liste_connex')
      suppressionListeMessages()
  )
  
suppressionConnexions()
#Initialisation des variables
users = new Object()

sharypicAPIKey  = process.env.PSLIVE_SHARYPIC_APIKEY
sharypicAPIKey  = 'ad8ca32f31fabe8643d29308'
admin_password  = process.env.PSLIVE_ADMIN_PASSWORD
admin_password  = ""

liste_connex    = []
redis.scard('liste_connex',(error, count) ->
  console.log('Init de la liste des connexions: '+count+' connexion(s)') 
)




livedraw_iframe = '<iframe scrolling="no", frameborder="0" src="/noshary"></iframe>'
episode         = 'Bienvenue sur le balado qui fait aimer la science!'

redis.get("livedraw_iframe",(err, replies)->
    console.log('iframe:'+replies)
    livedraw_iframe=replies
)
redis.get("episode",(err, replies)->
    console.log('episode:'+replies)
    episode=replies
)



update_compteur = () ->
  redis.scard('liste_connex',(error, count_cnx) ->
      io.sockets.emit('update_compteur',{
        connecte:compte(users),
        cache:count_cnx-compte(users)
      })
    )

#Fonction pour la gestion de SharyPic
getIframeStr = (jsonData) -> 
  return '<iframe width="640" height="480" scrolling="no" frameborder="0" src="http://www.sharypic.com/events/'+jsonData.uid+'/widget?collection=all&theme=dark&autoplay=true&share=true&scoped_to=all&timing=20000"><a href="https://www.sharypic.com/'+jsonData.uid+'/all" title="'+jsonData.description+'" >'+jsonData.description+'</a></iframe>'
  

    
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
    data = ''
    res.on('data', (chunk) ->
        data += chunk
    )
    res.on('end',() ->
        console.log("Event SharyPic cree : " +  data)
        jsonData = JSON.parse data
        livedraw_iframe = getIframeStr(jsonData)
        redis.set("livedraw_iframe",livedraw_iframe)
        io.sockets.emit('new-drawings',livedraw_iframe)
    )
  ).on('error', (e) ->  console.log("Got error: " + e.message))
  req.write(param);
  req.end();
#Fin des Fonctions pour la gestion de SharyPic







io.sockets.on 'connection', (socket) ->
  console.log "Nouvelle connexion... ("+io.sockets.clients().length+" sockets)"



  #connexion a la page de live. L'utilisateur n'est pas connecté.
  #Les valeurs sont donc initialisées pour cela
  me = false
  id_connexion= false

  
  init_connexion = (socket) ->
    id_connexion = md5(Date.now())
    redis.sadd('liste_connex',id_connexion)
    #Envoi des messages récents au client
    redis.llen('all_messages',  (error, nombre) ->
      debut = Math.max(nombre-10,0)
      console.log("debut:"+debut+'/'+nombre)
      redis.lrange('all_messages', debut, -1, (error2, items) ->
        items.map((message) -> socket.emit('nwmsg',JSON.parse(message)))
      )
    )
    #Envoi des parametres du live
    socket.emit('new-drawings',livedraw_iframe)
    socket.emit('new-title',episode)
    for key, value of users
      console.log('Ajout du user '+value.mail)
      socket.emit('newuser',value)

    
    
    
  # gestion de la connexion au live. Le client evoi un Hello au serveur
  # qui lui reponf Olleh avec un id qui permettra de au serveur de s'assurer
  # que le client est connu (notamment compté)
  socket.on 'Hello', (id_demande) ->
    #verification si l'id est connu
    redis.sismember("liste_connex",id_demande,(err, res) ->
      if !res
        init_connexion(socket)
      else
        id_connexion=id_demande
      #envoi de Olleh
      console.log('Hello recu. Envoi du Olleh')
      socket.emit('Olleh',id_connexion)
      #mise a jour du compteur
      update_compteur()
    )
    
    
    
    
    
    
  #Login : l'utilisateurs se connecte a la Chatroom
  socket.on 'login', (user) ->
    #Verification si le client est connu. dans le cas contraire, on le deconnecte
    verif_connexion(user.id_connexion,()->)
        
    #Verification de la validité de l'identification
    unless  validator.isEmail(user.mail)
      socket.emit('erreur',"Email invalide")
      return -1
    unless validator.isLength(user.username,3,30)
      socket.emit('erreur',"Le nom d'utilisateur doit être compris entre 3 et 30 lettres")
      return -1

    try

      # Verification de l'existance de l'utilisateur
      # Le cas échéant, on incremente un compteur
      for key, existing_user of users
        console.log 'Verif '+existing_user.mail+'/'+existing_user.username
        if (user.mail == existing_user.mail) && (user.mail!='')
          me = existing_user
          console.log '\tuser already exist!'
          me.cpt += 1
          console.log '\tcpt '+me.mail+':'+me.cpt

      #dans le cas contraire, on le créé dans la userlist
      unless me
        me = user
        #me.id = user.mail.replace('@','-').replace(/\./gi, "-")
        me.id = Date.now()
        me.cpt=1
        console.log 'cpt '+me.mail+':'+me.cpt
        me.avatar = 'https://gravatar.com/avatar/' + md5(user.mail) + '?s=40'
        users[me.id] = me
        #on informe tout le monde qu'un nouvel utilisateur s'est connecté
        io.sockets.emit('newuser',me)
        
        update_compteur()
      #on informe l'utilisateur qu'il est bien cnnecté
      socket.emit('logged')

  
        
   


  #Verification de la connexion
  verif_connexion=(id_connexion_loc,callback)->
    console.log("Verif si la connexion "+id_connexion_loc+" existe")
    redis.sismember("liste_connex",id_connexion_loc,(err, res) ->
      if res
        callback()
      else
        console.log("Une connexion inconnu a été repérée")
        socket.emit('disconnect',"Utilisateur inconnu")
    )



 #Serie de fonctions gérant la deconnexion
  deconnexion=() ->
    #On supprime la connexion de la liste
    console.log('Suppression de la connexion '+id_connexion)
    redis.srem("liste_connex",id_connexion)
    #on met a jour le compteur des autres users
    update_compteur()
    #si le une connexion a la chatroom existe, on le delg
    unless me == false
      logout()
    

  #gestion de la deconnexion de la chatroom
  logout=() ->
    #on decremente le compteur de cnx du l'utilisateur
    me.cpt -= 1
    console.log 'cpt '+me.mail+':'+me.cpt
    unless(me.cpt > 0)
      #si le compteur arrive a 0, on le supprime de la userlist
      #et on en informe les autres clients
      delete users[me.id]
      io.sockets.emit('disuser',me)
      update_compteur()




  socket.on 'disconnect', ->
    #gestion de la coupure de connexion du client
    console.log 'Deconnexion de '+me.name
    verif_connexion(id_connexion,deconnexion)



  # gestion des messages
  socket.on 'nwmsg', (message) ->
    verif_connexion(message.id_connexion,()->
      message.user = me
      date = new Date()
      message.message = replaceURLWithHTMLLinks(validator.escape(message.message))
      message.message = replaceSalaud(message.message)
      h = pad2(date.getHours())
      m = pad2(date.getMinutes())
      s = pad2(date.getSeconds())
      message.ts = h+":"+m+":"+s
      message_JSON=JSON.stringify(message)
      console.log('JSON:'+message_JSON)
      redis.rpush('all_messages',message_JSON)   
      io.sockets.emit('nwmsg',message)
    )
            

  #GESTION DE L'admin (qui n'envoi pas de HELLO)
            


  # Changement du titre et chargement de l'iframe
  socket.on 'change-title', (message) ->
    nomEvent= 'ps' +message.number
    if message.password == admin_password 
      options = {
        host: 'api.sharypic.com',
        port: 443,
        path: '/v1/user/events.json?api_key='+sharypicAPIKey
      }
      data = ''
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
            redis.set("livedraw_iframe",livedraw_iframe)
            #io.sockets.emit('new-drawings',livedraw_iframe)
            bTrouve=true    
            dateref=value.created_at
        if !bTrouve && message.createEvent
          createSharypicEvent(nomEvent,message.title)
        else
          io.sockets.emit('new-drawings',livedraw_iframe)
        
      episode= "<span class='number'> Episode #"+(message.number)+" - </span> "+message.title
      redis.set("episode",episode)
      io.sockets.emit('new-drawings',livedraw_iframe)
      io.sockets.emit('new-title',episode)
        
  # Reitinialisation de la chatroom
  socket.on 'reinit_chatroom', (password) ->
    if password == admin_password
      console.log("Reinitiailisation de la chatroom")
      suppressionListeMessages()
      livedraw_iframe='<iframe scrolling="no", frameborder="0" src="/noshary"></iframe>'
      episode='Bienvenue sur le balado qui fait aimer la science!'
      redis.set("livedraw_iframe",livedraw_iframe)
      redis.set("episode",episode)
      io.sockets.emit('del_msglist')
      io.sockets.emit('new-drawings',livedraw_iframe)
      io.sockets.emit('new-title',episode)
 
        