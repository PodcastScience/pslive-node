
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
AWS = require('aws-sdk')
#AWS.config.loadFromPath('./configAWS.json');
AWS.config.update({region: 'eu-west-1'});
s3 = new AWS.S3()


app = express()

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
  res.send all_messages.map((message) -> "<b>#{message.user.username}:</b> #{message.message}").join("<br/>")
app.get '/noshary', (req, res) ->
  res.send "Pas de dessins ce soir :("
app.get '/timestamp', (req, res) ->
  res.send all_messages.map((message) -> 
    "<b>#{message.user.username}</b> [#{(message.h+2)%24}:#{message.m}:#{message.s}]: <span id='[#{(message.h+2)%24}:#{message.m}:#{message.s}]'>#{message.message}</span>"
  ).join("<br/>")
app.get '/questions', (req, res) ->
  res.send all_messages.filter( (msg,idx) -> 
    console.log(msg.message+'/'+idx)
    if typeof(msg)!='undefined' && typeof(msg.message)!='undefined'
      msg.message.indexOf("@ps")>-1 || msg.message.indexOf("@PS")>-1
    else
      false
  ).map((message) -> 
    "<b>#{message.user.username}</b><a href='/timestamp#[#{(message.h+2)%24}:#{message.m}:#{message.s}]'>[#{(message.h+2)%24}:#{message.m}:#{message.s}]</a>: #{message.message}"
  ).join("<br/>");

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



## Chargement de la chatroom dans Amazon S3
livedraw_iframe = '<iframe scrolling="no", frameborder="0" src="/noshary"></iframe>'
episode = 'Bienvenue sur le balado qui fait aimer la science!'


s3.client.getObject({
  Bucket: 'chatroomPodcastScience',
  Key: 'episodePodcastScience.JSON'
},  (error,res) ->
  if(!error)
    console.log("chargement episode ok")
    livedraw_iframe=JSON.parse(res.Body).iframe
    episode=JSON.parse(res.Body).titre
  else
    console.log("erreur chargement episode")
  
 )

#Initialisation des variables
users = new Object()
last_messages = []  
all_messages = []
history = 10
sharypicAPIKey = process.env.PSLIVE_SHARYPIC_APIKEY
#sharypicAPIKey = ''
admin_password = process.env.PSLIVE_ADMIN_PASSWORD
#admin_password = ""


#Chargement de l'historique des messages
liste_connex    = []
s3.client.getObject({
  Bucket: 'chatroomPodcastScience',
  Key: 'messagesPodcastScience.JSON'
}, (error,res) ->
  if(!error)
    all_messages=JSON.parse(res.Body)
    for msg in all_messages
      console.log("chargement derniers messages:"+msg.message)
      last_messages.push msg
      last_messages.shift() if (last_messages.length > history)
  console.log(JSON.stringify(all_messages))
)


console.log('Init de la liste des connexions: '+compte(liste_connex)+' connexion(s)')



#Fonction pour la gestion de SharyPic
getIframeStr = (jsonData) -> 
  '<iframe width="640" height="480" scrolling="no" frameborder="0" src="http://www.sharypic.com/events/'+jsonData.uid+'/widget?collection=all&theme=dark&autoplay=true&share=true&scoped_to=all&timing=20000"><a href="https://www.sharypic.com/'+jsonData.uid+'/all" title="'+jsonData.description+'" >'+jsonData.description+'</a></iframe>'
  

    
createSharypicEvent = (name,libelle) ->
  console.log("Creation de l'event SharyPic : " + name)
  param=JSON.stringify({
    name: name,
    pname: name,
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


  envoieInitialChatroom = () ->
    console.log("envoi de l'historique")
  #Envoi des messages récents au client
    for message in last_messages
      socket.emit('nwmsg',message)
    #Envoi des parametres du live
    socket.emit('new-drawings',livedraw_iframe)
    socket.emit('new-title',episode)
    
    
    
    
  # gestion de la connexion au live. Le client evoi un Hello au serveur
  # qui lui reponf Olleh avec un id qui permettra de au serveur de s'assurer
  # que le client est connu (notamment compté)
  socket.on 'Hello', (id_demande) ->
    #calcul de l'id
    if(id_demande=='')
      console.log("generation de l'id")
      id_connexion = md5(Date.now())
    else
      id_connexion = id_demande
    liste_connex[id_connexion]=''
    
    #envoi de Olleh
    console.log('Hello recu. Envoi du Olleh : '+id_connexion)
    socket.emit('Olleh',id_connexion)
    if(id_demande=='')
      envoieInitialChatroom()
    #mise a jour du compteur et de la userlist pour tous les connectés
    io.sockets.emit('update_compteur',{
      connecte:compte(users),
      cache:compte(liste_connex)-compte(users)
    })
    console.log('Ouverture de la connexion '+id_connexion+'. '+compte(liste_connex)+' connexions ouvertes')
    for key, value of users
      console.log('Ajout du user '+value.mail)
      socket.emit('newuser',value)
    
    
    
    
    
  #Login : l'utilisateurs se connecte a la Chatroom
  socket.on 'login', (user) ->
    #Verification si le client est connu. dans le cas contraire, on le deconnecte
    verif_connexion(user.id_connexion)
        
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
        
        io.sockets.emit('update_compteur',{
          connecte:compte(users),
          cache:compte(liste_connex)-compte(users)
        })
      #on informe l'utilisateur qu'il est bien cnnecté
      socket.emit('logged')

  
        
      


  #Verification de la connection
  verif_connexion=(id_connexion_loc)->
    console.log("Verif si la connexion "+id_connexion_loc+" existe")
    for key, val of liste_connex
      console.log(key)
      if (key == id_connexion_loc)
        return true
    #Si ce n'est pas le cas, on le deconnecte.
    #Sa reaction sera normalement de se reconnecter proprement immediatement
    console.log("Une connexion inconnu a été repérée")
    socket.emit('disconnect',"Utilisateur inconnu")
    return false



 #Serie de fonctions gérant la deconnexion
  deconnexion=() ->
    #On supprime la connexion de la liste
    console.log('Suppression de la connexion '+id_connexion)
    delete liste_connex[id_connexion]
    #on met a jour le compteur des autres users
    io.sockets.emit('update_compteur',{
      connecte:compte(users),
      cache:compte(liste_connex)-compte(users)
    })
    console.log("Nombre d'utilisateurs : "+compte(liste_connex))
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
      io.sockets.emit('update_compteur',{
        connecte:compte(users),
        cache:compte(liste_connex)-compte(users)
      })


  maj_S3episode = () ->
    console.log("MAJ de l'episode")
    s3.client.putObject({
    Bucket: 'chatroomPodcastScience',
    Key: 'episodePodcastScience.JSON',
    Body: JSON.stringify({
      'titre':episode,
      'iframe':livedraw_iframe
      })
    },(res) ->  console.log('Erreur S3 : '+res) if res != null)

  socket.on 'disconnect', ->
    #gestion de la coupure de connexion du client
    console.log 'Deconnexion de '+me.name
    if verif_connexion(id_connexion)
      deconnexion()



  # gestion des messages
  socket.on 'nwmsg', (message) ->
    if verif_connexion(message.id_connexion)
      message.user = me
      date = new Date()
      message.message = replaceURLWithHTMLLinks(validator.escape(message.message))
      message.message = replaceSalaud(message.message)
      message.h = pad2(date.getHours())
      message.m = pad2(date.getMinutes())
      message.s = pad2(date.getSeconds())
      all_messages.push message
      last_messages.push message
      last_messages.shift() if (last_messages.length > history)
      io.sockets.emit('nwmsg',message)
      s3.client.putObject({
        Bucket: 'chatroomPodcastScience',
        Key: 'messagesPodcastScience.JSON',
        Body: JSON.stringify(all_messages)
      },(res) ->  console.log('Erreur S3 : '+res) if res != null)   
            

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
            bTrouve=true
            dateref=value.created_at
        if !bTrouve && message.createEvent
          createSharypicEvent(nomEvent,message.title)
        else
          io.sockets.emit('new-drawings',livedraw_iframe)
          maj_S3episode()
        
        
      episode= "<span class='number'> Episode #"+(message.number)+" - </span> "+message.title
      io.sockets.emit('new-title',episode)
      maj_S3episode()
        
        

  # Reitinialisation de la chatroom
                
  socket.on 'reinit_chatroom', (password) ->
    if password == admin_password
      console.log("Reinitiailisation de la chatroom")
      livedraw_iframe='<iframe scrolling="no", frameborder="0" src="/noshary"></iframe>'
      episode='Bienvenue sur le balado qui fait aimer la science!'
      last_messages = []  
      all_messages = []
      s3.client.putObject({
        Bucket: 'chatroomPodcastScience',
        Key: 'episodePodcastScience.JSON',
        Body: JSON.stringify({
          'titre':episode,
          'iframe':livedraw_iframe
        }),  
      },(res) ->  console.log('Erreur S3 : '+res) if res != null)
      s3.client.putObject({
        Bucket: 'chatroomPodcastScience',
        Key: 'messagesPodcastScience.JSON',
        Body: JSON.stringify(all_messages)
      },(res) ->  console.log('Erreur S3 : '+res) if res != null)
      io.sockets.emit('del_msglist')
      io.sockets.emit('new-drawings',livedraw_iframe)
      io.sockets.emit('new-title',episode)

