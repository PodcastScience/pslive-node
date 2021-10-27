
#require('coffeescript')
express = require('express')
routes = require('./routes')
#bodyParser = require('body-parser')
errorHandler  = require('errorhandler')
methodOverride  = require('method-override')
user = require('./routes/user')
http = require('http')
https = require('https')
path = require('path')
md5 = require('md5')
mu = require('mu2')
querystring  = require("querystring")
cheerio = require('cheerio')
url_parser = require('url')
validator = require('validator')
Twitter = require('./twitter');
Backend = require('./backend_interface');
PsImagesQueue = require('./ps_images_queue');
fs = require('fs')
mime = require('mime')
{ Server } = require('socket.io')
app = express()









#all environments
#app.use require('connect-assets')()
#console.log js('client')
app.set('port', process.env.PORT || 3001)
app.set('views', __dirname + '/views')
app.set('view engine', 'pug')
#app.use(express.favicon("/images/fav.png"))
#app.use(express.logger('dev'))
#app.use(bodyParser())
app.use(methodOverride())
#app.use(app.router)
app.use(express.static(path.join(__dirname, 'public')))
#app.locals.css = css
#app.locals.js = js
#development only
if ('development' == app.get('env'))
  app.use(errorHandler())








#router
app.get('/', routes.index)
app.get('/test', routes.test)
app.get('/presentation', routes.presentation)
app.get('/presentationfull', routes.presentationfull)
app.get('/admin', routes.admin)
app.get('/users', user.list)






app.get '/messages', (req, res) ->
  res.send all_messages.map((message) -> 
    message_me = ircLike_me message.message, message.user.username
    if message_me==message.message
      return "<b>#{message.user.username}:</b> #{message.message}"
    else
      return '*'+message_me
  ).join("<br/>")






app.get '/close', (req, res) ->
  res.send('<script>window.close()</script>')



app.get '/twitter_auth', (req, res) ->
  twitter.get_auth_step2(res,req)







app.get '/timestamp', (req, res) ->
  res.send all_messages.map((message) -> 
    message_me = ircLike_me message.message, message.user.username
    if message_me==message.message
      return "<b>#{message.user.username}</b> [#{(message.h+2)%24}:#{message.m}:#{message.s}]: <span id='[#{(message.h+2)%24}:#{message.m}:#{message.s}]'>#{message.message}</span>"
    else
      return '*'+message_me
    
  ).join("<br/>")






app.get '/questions', (req, res) ->
  res.send all_messages.filter( (msg,idx) -> 
    if typeof(msg)!='undefined' && typeof(msg.message)!='undefined'
      msg.message.indexOf("@ps")>-1 || msg.message.indexOf("@PS")>-1
    else
      false
  ).map((message) -> 
    "<b>#{message.user.username}</b><a href='/timestamp#[#{(message.h+2)%24}:#{message.m}:#{message.s}]'>[#{(message.h+2)%24}:#{message.m}:#{message.s}]</a>: #{message.message}"
  ).join("<br/>");








app.get '/liste_images', (req, res) ->
  backend.download_images (data)->
    console.log 'liste_images',data
    res.send data.map((image) -> 
      d = new Date(image.created_at)
      d.setHours(d.getHours() + 2)
      console.log 'd '+d
      date_str = pad2(d.getDate())+'/'+pad2(d.getMonth())+'/'+d.getFullYear()
      time_str = pad2(d.getHours())+':'+pad2(d.getMinutes())
      "<b>#{date_str} #{time_str}</b> : 
        <a href='#{image.url}'  style='display: inline-block;width:50px;height:50px;'>
          <img src='#{image.url}' style='max-width:50px;max-height:50px;'/>
        </a>
        <a href='#{image.url}'>
          #{image.url}
        </a>"
    ).join("<br/>")






app.post '/suppr_image', (req,res)->
  console.log "suppr_image:liste_images au début:" , liste_images
  if req.body.image=='{}' ||  req.body.image=='' || typeof(req.body.image)==undefined
    res.end ''
    return
  image = JSON.parse(req.body.image)
  if !(backend.test_emission_en_cours image.episode_id)
    console.log "suppr_image: mauvais episode",image.episode_id
    res.end ''
    return 
  images_queue.remove image.sign
  console.log "suppr_image",image
  idx=-1
  for _idx,i of liste_images
    if i.signature == image.sign
      idx=_idx
  img=liste_images.splice idx,1
  img.forEach (i)->
    console.log i
    console.log i.signature
    chatroomNamespace.emit 'remove_image', i.signature
  res.end ''






app.post '/post_image', (req,res)->
  if req.body.image=='{}' ||  req.body.image=='' || typeof(req.body.image)==undefined
    res.end ''
    return
  image = JSON.parse(req.body.image)
  if !(backend.test_emission_en_cours image.episode_id)
    console.log "suppr_image: mauvais episode",image.episode_id
    res.end ''
    return 
  console.log "+",image
  try
    if image.media_type == 'img'
      img = {
        'nom' : image.name, 
        'url' : image.url,
        'poster' : image.author,
        'poster_user' : image.user,
        'avatar' : image.avatar,
        'tweet' : image.msg,
        'media_type' : 'img',
        'created_at' : image.created_at,
        'updated_at' : image.updated_at
      }
    if image.media_type == 'video'
      img = {
        'nom' : image.name, 
        'url' : image.url,
        'poster' : image.author,
        'poster_user' : image.user,
        'avatar' : image.avatar,
        'tweet' : image.msg,
        'media_type' : 'video',
        'created_at' : image.created_at,
        'updated_at' : image.updated_at
      }
    meta_tmp.push img
    console.log "download_images/",img.url
  catch e
    console.log "download_images/pas d'image"
  console.log "-",image
  console.log "post_image",liste_images
  img.signature = image.sign
  liste_images.push img 
  images_queue.add img
  update_waiting_image()
  res.end ''






app.post '/update_queue', (req,res)->
  console.log "maj de la file d'attente",req.body
  if req.body.image=='{}' ||  req.body.image=='' || typeof(req.body.image)==undefined
    res.end ''
    return
  images_en_attente = JSON.parse(req.body.queue)
  _episode_id = JSON.parse(req.body.episode_id)
  if !(backend.test_emission_en_cours _episode_id)
    console.log "suppr_image: mauvais episode",image.episode_id
    res.end ''
    return false
  chatroomNamespace.emit 'maj_waiting_images',images_en_attente
  res.end ''
























httpServer = http.createServer(app).listen(app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))
)

is_admin = (user) =>
  for adm in admin_list
    console.log "is "+user.mail+" admin?",adm
    return true if adm==user.mail
  return false


ircLike_me= (text,pseudo) -> 
  stringTab = text.split(" ")
  stringMe = text.split("/me")     
  valeurRetour =""
  if stringTab.length >= 2
    if stringTab[0].localeCompare("/me")==0
      valeurRetour = "<i> "
      valeurRetour = valeurRetour.concat(pseudo) 
      valeurRetour = valeurRetour.concat(stringMe[1])
      valeurRetour = valeurRetour.concat("</i>")
    else
      valeurRetour=text
  else
    valeurRetour=text
  return valeurRetour


#socket.io configuration
io = new Server(httpServer,({
    "transports": ['websocket','polling'],
    'heartbeat timeout': 200
}))
chatroomNamespace=io.of('/chatroom')






#Initialisation des variables
users = new Object()

console.log("ici",process.env.PSLIVE_ADMINLIST)

admin_list=JSON.parse(process.env.PSLIVE_ADMINLIST)
console.log("la")
auth_twitter = {
    consumer_key:         process.env.PSLIVE_TWITTER_CONSUMERKEY,
    consumer_secret:      process.env.PSLIVE_TWITTER_CONSUMERSECRET,
    access_token_key:     process.env.PSLIVE_TWITTER_TOKENKEY,
    access_token_secret:  process.env.PSLIVE_TWITTER_TOKENSECRET
}
console.log auth_twitter
twitter = new Twitter(auth_twitter)
backend = new Backend({ 
    url:  (process.env.PSLIVE_BACKEND_URL || 'localhost') ,
    port: (process.env.PSLIVE_BACKEND_PORT || 3000)
  })

images_queue = new PsImagesQueue { chatroomNamespace: chatroomNamespace, delay:10000}

last_messages     = []
all_messages      = []
liste_images      = []
images_en_attente = []
history           = 10
nomEvent          = ''
hashtag           = ''
num_episode       = ''
id_episode        = 0
title_episode     = ''
admin_password    = process.env.PSLIVE_ADMIN_PASSWORD
episode           = 'Bienvenue sur le balado qui fait aimer la science!'




###############################
####  functions ###############
###############################

#simple
replaceURLWithHTMLLinks = (text) -> 
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  retval= text.replace(exp,"<a href='$1' target='_blank'>$1</a>")
  console.log "Detection d'une url", text.replace(exp,"<a href='$1' target='_blank'>$1</a>")
  return retval


insertChatroomImages = (text,user,avatar,socket_) -> 
  exp = /https?:\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|]/i
  console.log text
  if tab_url = text.match(exp)
    console.log tab_url
    tab_url.map (url)->
      url=url.replace(/\/$/,'')
      get_image url, (nom,data,content_type)->
        console.log "****************image*********"
        console.log "****************image*********",content_type
        if(content_type == 'image/jpeg' || content_type == 'image/gif' || content_type == 'image/png' )
          switch content_type
            when 'image/jpeg' then img_format='jpg'; break;
            when 'image/gif' then img_format='gif'; break;
            when 'image/png' then img_format='png'; break;
          nom=md5(nom)+'.'+img_format
          param_img={
            'nom' : nom, 
            'poster':user,
            'poster_user':user,
            'avatar':avatar,
            'tweet':replaceURLWithHTMLLinks text
            'media_type' : 'img'
          }
          console.log "****************image*********",param_img
          img_format=img_format.toUpperCase()
          for idx,i of liste_images
            if i.nom==nom
              console.log "image deja presente"
              return false
          backend.upload_image nomEvent, nom, user,user,avatar, text, data,img_format, (url_wp)->  
            if url_wp=="TOO_BIG"
              socket_.emit "ERR_IMTOOBIG"
              console.log "image trop grosse"
            else
              console.log "image uploadée"
              param_img.url=url_wp
              param_img.signature = md5(url_wp)
              console.log param_img
              liste_images.push param_img 
              images_queue.add param_img
              #chatroomNamespace.emit 'add_img',param_img
              console.log 'media:'+ nom
        else 
          console.log "ceci n'est pas une image"



replaceSalaud = (text) ->
  exp=/salaud/ig
  retval=text.replace(exp,"salop\*")
  if (text!=retval)
    retval=retval+"<br><span style='font-weight:lighter;font-size:x-small;'>*Correction apportée selon la volonté du DictaTupe.</span>"
  return retval



#fonction pour compter (.length ne marche pas.... a voir)
compte = (tab)->
  cpt=0
  for key,elt of tab
    cpt=cpt+1
  return cpt      
  
pad2 = (val) ->
  if (val<10)
    return  '0'+val
  else
    return val
  
#------------------------------------
#Fonction pour la gestion des images
get_image = (url,cb) ->
  nom=url.slice url.lastIndexOf('/')+1
  exp = /https:\/\//i
  if url.match(exp)
    proto=https 
  else
    proto=http
  console.log "chargement images en RAM 2: ",url
  try
    proto.get url,{headers:{'User-Agent': 'podcastsciencebot/0.0 (https://podcastscience.fm; pascal@podcastscience.fm) generic-library/0.0'}} ,(response)->
      response.setEncoding('binary');
      console.log "image chargée"
      content_type=response.headers['content-type']
      data=''
      console.log "appel de la callback"
      if !(content_type == 'image/jpeg' || content_type == 'image/gif' || content_type == 'image/png' )
        console.log "Erreur de content-type",response
        cb nom,data,content_type
      response.setEncoding('binary')
      console.log "reception d'une reponse"
      response.on 'data',
        (chunk)->data+=chunk
        console.log "data"
      response.on 'end',()->
        console.log "Fin du chargement de "+nom+":"
        cb nom,data,content_type
  catch e
    console.log "erreur dans le telechargement de l'image"  ,e


get_image_twitter = (url,cb) ->
  nom=url.slice url.lastIndexOf('/')+1
  console.log "chargement images en RAM : ",url
  http.get url+':large', (response)->
      data=''
      content_type=response.headers['content-type']
      response.setEncoding('binary')
      console.log "reception d'une reponse"
      response.on 'data',
        (chunk)->data+=chunk
        console.log "data"
      response.on 'end',()->
        console.log "Fin du chargement de "+nom+":"
        cb nom,data,content_type


get_thumbnail = (site,url,cb) ->
  if site=='vine.co'
    console.log "chargement du thumbnail Vine",url
    https.get url.replace('http://','https://'), (response)->
      data=''
      response.on 'data',(chunk)->
        data+=chunk
      response.on 'end',()->
        console.log "pages chargee",data
        $ = cheerio.load(data)
        cb $('meta[property="twitter:image"]').attr('content')      
  else
    cb ""

 

liste_connex    = []
  
load_episode = (number,title,_hashtag,chatroom) =>
    console.log "*********************************************************"
    all_messages  = (chatroom || [])
    last_messages = []
    for msg in all_messages
      last_messages.push msg
      last_messages.shift() if (last_messages.length > history)
    nomEvent = number
    if nomEvent == 'podcastscience'
      num_episode = ''
      title_episode = ''
      hashtag =  ''
      episode=title
    else
      num_episode = number.substring(2)
      title_episode = title
      hashtag = _hashtag
      episode= "<span class='number'> Episode #"+number+" - </span> "+title

    update_waiting_image()
    backend.download_images (meta)->      
      liste_images=meta
    twitter.stream {track: '#'+hashtag} 

console.log 'backend',backend

backend.get_default_emission( load_episode )



update_waiting_image= ()->
  backend.get_queue (data)-> 
    images_en_attente=data
    chatroomNamespace.emit 'maj_waiting_images',data





send_chatroom = (socket_) ->
  console.log("envoi de l'historique")
  if nomEvent != 'podcastscience'
    for message in last_messages
      console.log 'send_chatroom/message:',message
      socket_.emit('nwmsg',message)
    for im in liste_images
      console.log 'send_chatroom/images',im
      site = im.url.split('/')[0]
      get_thumbnail site,'https://'+im.url,(url_thumbnail) ->
        im.url_thumbnail=url_thumbnail
        im.signature=md5 im.url
        socket_.emit('add_img',im) 
  update_waiting_image()
  console.log 'socket:',socket_
  console.log 'send_chatroom/episode:',episode
  socket_.emit 'new-title',episode,num_episode,title_episode,hashtag

change_chatroom = () ->
  chatroomNamespace.emit 'del_imglist'
  chatroomNamespace.emit 'del_msglist'
  send_chatroom chatroomNamespace



chatroomNamespace.on 'connection', (socket) ->
  console.log "*********************************************************************************************"
  console.log "*********************************************************************************************"
  console.log "*********************************************************************************************"
  console.log "*********************************************************************************************"
  console.log "Nouvelle connexion... ("+chatroomNamespace.sockets.size+" sockets)"



  #connexion a la page de live. L'utilisateur n'est pas connecté.
  #Les valeurs sont donc initialisées pour cela
  me = false
  id_connexion= false
  cpt_message=0
  id_last_message=""

  envoieInitialChatroom = () ->
    #Envoi des messages récents au client
    send_chatroom socket

  socket.on 'twitter_auth', () ->
    console.log  "demande d'auth twitter"
    verif_connexion(id_connexion)
    twitter.get_auth(socket,id_connexion)

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
    chatroomNamespace.emit('update_compteur',{
      connecte:compte(users),
      cache:compte(liste_connex)-compte(users)
    })
    console.log('Ouverture de la connexion '+id_connexion+'. '+compte(liste_connex)+' connexions ouvertes')
    for key, value of users
      console.log('Ajout du user '+value.mail)
      socket.emit('newuser',value,false)
    
    
  socket.on 'twitter_login', (tocken,id_connexion,reco)->
    console.log "connexion Twitter",tocken
    verif_connexion(id_connexion)
    twitter.get_auth_info tocken, (user)->
      console.log "user twitter", user
      connect_user user,reco,'twitter'
    
    
  #Login : l'utilisateurs se connecte a la Chatroom
  socket.on 'login', (user,reco) ->
    console.log "demande de login:",user
    #Verification si le client est connu. dans le cas contraire, on le deconnecte
    verif_connexion(user.id_connexion)
        
    #Verification de la validité de l'identification
    unless  validator.isEmail(user.mail)
      socket.emit('erreur',"Email invalide")
      return -1
    unless validator.isLength(user.username,3,30)
      socket.emit('erreur',"Le nom d'utilisateur doit être compris entre 3 et 30 lettres")
      return -1
    user.avatar= 'https://gravatar.com/avatar/' + md5(user.mail) + '?s=40'
    connect_user user,reco ,'email'

  connect_user = (user,reco,source) ->
    console.log "connexion du user",user
    try
      # Verification de l'existance de l'utilisateur
      # Le cas échéant, on incremente un compteur
      me=null
      for key, existing_user of users
        console.log 'Verif '+existing_user.mail+'/'+existing_user.username
        if (user.mail == existing_user.mail) && (user.mail!='')
          me = existing_user
          console.log '\tuser already exist!'
          me.cpt += 1
          console.log '\tcpt '+me.mail+':'+me.cpt

      console.log "me:",me
      #dans le cas contraire, on le créé dans la userlist
      unless me
        console.log "creation du user"
        me = user
        #me.id = user.mail.replace('@','-').replace(/\./gi, "-")
        me.id = Date.now()
        me.cpt=1
        console.log 'cpt '+me.mail+':'+me.cpt
        #me.avatar = 'https://gravatar.com/avatar/' + md5(user.mail) + '?s=40'
        users[me.id] = me
        #on informe tout le monde qu'un nouvel utilisateur s'est connecté
        chatroomNamespace.emit 'newuser', me, !reco
        
        chatroomNamespace.emit 'update_compteur',
          connecte:compte(users),
          cache:compte(liste_connex)-compte(users)

      #on informe l'utilisateur qu'il est bien cnnecté
       _is_admin=is_admin(me)
       if _is_admin
        backend_url=backend.get_backend_url()
      else
        backend_url=''
      socket.emit 'logged', me.id, _is_admin,backend_url
      socket.emit  'pause_slide_show',images_queue.get_pause()
      if source=='twitter'
        socket.emit 'twitter_logged',user
    catch e
      console.log "erreur de connexion",e
      
      



        
      


  #Verification de la connection
  verif_connexion=(id_connexion_loc)->
    console.log("Verif si la connexion "+id_connexion_loc+" existe")
    for key, val of liste_connex
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
    chatroomNamespace.emit('update_compteur',{
      connecte:compte(users),
      cache:compte(liste_connex)-compte(users)
    })
    console.log("Nombre d'utilisateurs : "+compte(liste_connex))
    #si le une connexion a la chatroom existe, on le delg
    unless me == false
      logout()
    
  searchPseudoInit= (text) ->
    userlist=[]
    text=text.trim()
    for key, user of users
      userlist.push {name:user.username,key:key}
    console.log "recherche d'un pseudo initial dans "+text+":",userlist
    for u in userlist.sort((a,b)-> b.name.length-a.name.length)
      pattern=RegExp("^@("+u.name+")","ig")
      pseudo=text.match(pattern)

      console.log "recherche de *@"+u.name+"* dans "+text+" : *"+pseudo+"*",(pseudo==('@'+u.name))
      if pseudo!=null
        console.log "pseudo touvé",u.name
        #+1 pour le @
        reason=text.slice(u.name.length+1).trim()
        return {pseudo:u.name,reason:reason,key:u.key}
    console.log "aucun pseudo trouvé"
    return {pseudo:'',reason:text,key:null}

  #gestion de la deconnexion de la chatroom

  logoutUser=(u) ->
    #on decremente le compteur de cnx du l'utilisateur
    console.log "entrée dans logoutUser",u
    u.cpt -= 1
    console.log 'cpt '+u.mail+':'+u.cpt
    #u=null
    unless(u.cpt > 0)
      #si le compteur arrive a 0, on le supprime de la userlist
      #et on en informe les autres clients
      console.log "suppression de "+u.username
      delete users[u.id]
      chatroomNamespace.emit('disuser',u)
      chatroomNamespace.emit('update_compteur',{
        connecte:compte(users),
        cache:compte(liste_connex)-compte(users)
      }) 

  logout=() ->
    logoutUser me

  socket.on 'logout',()->
    console.log "demande de logout",me
    chatroomNamespace.emit 'kick',me.username,me.username+" s'est déconnecté(e)"
    logoutUser me

  ircLike_nick= (text) -> 
    stringTab = text.split(" ")
    console.log "avant",users
    stringNick = text.split("/nick ")     
    if stringTab.length >= 2 && stringTab[0].localeCompare("/nick")==0
      formername = me.username
      if stringNick[1]!=''
        me.username = stringNick[1]
        users[me.id].username = me.username
        console.log "apres",users
        chatroomNamespace.emit 'changename',formername,me
      return true
    return false



  ircLike_kick= (text) -> 
    return true if me == null
    stringTab = text.split(" ")
    stringKick = text.split("/kick")     
    valeurMessage =""
    if stringTab.length >= 2
      if stringTab[0].localeCompare("/kick")==0
        if stringKick[1]!=''    
          if !is_admin(me)
            chatroomNamespace.emit 'chatroom_info',"Non "+me.username+" ! Tu n'as pas le droit de kicker les gens !!!"
            return true
          param = searchPseudoInit stringKick[1]
          console.log param
          if param.pseudo=='' || param.pseudo==me.username
            return true
          valeurMessage = valeurMessage.concat(param.pseudo)
          valeurMessage = valeurMessage.concat(" s'est fait éjecter par ")
          valeurMessage = valeurMessage.concat(me.username) 
          if param.reason != ''
            valeurMessage = valeurMessage.concat(" ( "+param.reason+" )")
          chatroomNamespace.emit 'kick',param.pseudo,valeurMessage
          logoutUser users[param.key]
        return true
      else
        return false
    else
      return false

  biere= (text) -> 
    stringTab = text.split(" ")
    stringBiere = text.split("/bière")     
    valeurMessage =""
    if stringTab.length >= 2
      if stringTab[0].localeCompare("/bière")==0
        if stringBiere[1]!=''

          valeurMessage = valeurMessage.concat(me.username) 
          valeurMessage = valeurMessage.concat(" offre une bière à ")
          valeurMessage = valeurMessage.concat(stringBiere[1])
          valeurMessage = valeurMessage.concat("<img class='inline' src='images/biere.png'>")
          chatroomNamespace.emit 'chatroom_info',valeurMessage
        return true
      else
        return false
    else
      return false

  tournee= (text) -> 
    stringTab = text.split(" ")
    stringBiere = text.split("/tournéegénérale")     
    valeurMessage =""
    if stringTab.length >= 2
      if stringTab[0].localeCompare("/tournéegénérale")==0
        valeurMessage = valeurMessage.concat(me.username) 
        valeurMessage = valeurMessage.concat(" offre une bière à tout le monde")
        valeurMessage = valeurMessage.concat("<img class='inline' src='images/biere.png'>")
        chatroomNamespace.emit 'chatroom_info',valeurMessage
        return true
      else
        return false
    else
      return false

  socket.on 'changename',(name) ->
    formername = me.username
    me.username = name
    users[me.id].username = me.username
    chatroomNamespace.emit 'changename',formername,me


  socket.on 'disconnect', ->
    #gestion de la coupure de connexion du client
    console.log 'Deconnexion de '+me.name
    if verif_connexion(id_connexion)
      deconnexion()

  socket.on 'test', () ->
    console.log "test"


  # gestion des messages
  socket.on 'nwmsg', (message) ->
    if verif_connexion(message.id_connexion)
      if ! ircLike_nick(message.message,me) && ! biere(message.message) && ! tournee(message.message) &&  ! ircLike_kick(message.message,me)
        cpt_message+=1
        message.user = me
        date = new Date()
        message.message = replaceURLWithHTMLLinks((message.message))
        insertChatroomImages message.message , message.user.username ,message.user.avatar,socket
        message.message = replaceSalaud(message.message)
        id_last_message = md5(Date.now()+cpt_message+message.user.mail)
        message.id = id_last_message
        message.h = pad2(date.getHours())
        message.m = pad2(date.getMinutes())
        message.s = pad2(date.getSeconds()) 
        console.log 'nwmsg:',message
        all_messages.push message
        last_messages.push message
        last_messages.shift() if (last_messages.length > history)
        chatroomNamespace.emit('nwmsg',message)
        backend.set_chatroom JSON.stringify(all_messages)
   
    
  socket.on 'editmsg', (message) -> 
    console.log("demande de modif de message : "+message.message)
    if verif_connexion(message.id_connexion)
      message.message = replaceURLWithHTMLLinks((message.message))
      message.message = replaceSalaud(message.message)
      message.user = me
      message.id = id_last_message
      chatroomNamespace.emit('editmsg',message)
      for key,elt of all_messages
        elt.message = message.message if elt.id == id_last_message
      for key,elt of last_messages
        elt.message = message.message if elt.id == id_last_message
      backend.set_chatroom JSON.stringify(all_messages)
    
  #GESTION DE L'admin (qui n'envoi pas de HELLO)
            


  # Changement du titre et lancement du scan de twitter
  socket.on 'change-title', (message) ->
    nomEvent= 'ps' +message.number
    hashtag= message.hashtag.trim()
    if hashtag==''
      hashtag=nomEvent

    num_episode = message.number
    title_episode = message.title

    if message.password == admin_password  || is_admin(me)
      episode= "<span class='number'> Episode #"+(message.number)+" - </span> "+message.title
      backend.select_emission(nomEvent,message.title,hashtag, (res) -> 
        console.log 'change-title',res
        all_messages  = (res || [])
        last_messages = []
        for msg in all_messages
          last_messages.push msg
          last_messages.shift() if (last_messages.length > history)
        update_waiting_image()
        backend.download_images (meta)->      
          liste_images=meta
          change_chatroom()
      )
      try
        twitter.destroy()
      try
        twitter.stream {track: '#'+hashtag} 
      catch e
        console.log "erreur Twitter",e
    else
        socket.emit 'AuthFailed'
        
 


  # Reitinialisation de la chatroom
#                
  socket.on 'reinit_chatroom', (password) ->
    if password == admin_password  || is_admin(me)
      console.log("Reinitiailisation de la chatroom")
      episode       = 'Bienvenue sur le balado qui fait aimer la science!'
      nomEvent      = "podcastscience"
      hashtag       = ""
      title_episode = ""
      num_episode   = ""
      backend.select_emission(nomEvent,episode,hashtag, (res) -> 
          console.log 'reinit_chatroom',res
          last_messages = []  
          all_messages = []
          images_en_attente=[]
          chatroomNamespace.emit 'maj_waiting_images',[]
          backend.download_images (meta)->
            liste_images=meta
            change_chatroom()
        )
      try
        twitter.destroy()

  socket.on 'select_img',(signature)->
    console.log "demande de selection d'une image",signature
    if is_admin(me)
      console.log "demande acceptée"
      chatroomNamespace.emit 'select_img',signature 



  socket.on 'post-waiting-image', (signature)->
    console.log "demande de l'envoi d'une image en attente ",signature
    if is_admin(me)
      backend.post_waiting_image signature


  socket.on 'pause_slide_show', () -> 
    if is_admin(me)
      b_pause= images_queue.pause()
      chatroomNamespace.emit 'pause_slide_show',b_pause

  socket.on "test", () ->
    console.log 'test'
    #insertChatroomImages 'http://www.lecosmographe.com/blog/wp-content/uploads/2013/08/ngc1232-690x690.jpg' , 'pascal' ,'http://www.lecosmographe.com/blog/wp-content/uploads/2013/08/ngc1232-690x690.jpg',socket
    #insertChatroomImages 'http://www.astrosurf.com/luxorion/Images/m20-hyp.jpg' , 'pascal' ,'http://www.astrosurf.com/luxorion/Images/m20-hyp.jpg',socket




init_twitter = (twitter) ->
  twitter.on 'data', (data) -> 
    if typeof(data.extended_tweet)=='undefined'
      entities=data.entities
    else
      entities=data.extended_tweet.entities
    
    console.log "reception : ",data
    console.log "url : ", entities.urls
    
    try
      url         = entities.media[0].media_url
      console.log 1
      poster      = data.user.name
      console.log 2
      poster_user = data.user.screen_name
      console.log 3
      avatar      = data.user.profile_image_url
      console.log 4
      tweet       = data.text
      media_type  = 'img'
      console.log "Ceci est une image"
    catch e
      console.log "Ceci n'est pas une image"
      try
        site = entities.urls[0].display_url.split('/')[0]
        if site=='vimeo.com' || site=='youtube.com'  || site=='vine.co' 
          url         = entities.urls[0].display_url
          poster      = data.user.name
          poster_user = data.user.screen_name
          avatar      = data.user.profile_image_url
          tweet       = data.text
          media_type  = 'video'
      catch e
    return 0 if (url==null) || (typeof(url) == 'undefined')

    if media_type == 'img'
      get_image_twitter url, (nom,data,content_type)->
        param_img={
          'nom' : nom, 
          'poster':poster,
          'poster_user':poster_user,
          'avatar':avatar,
          'tweet':replaceURLWithHTMLLinks tweet
          'media_type' : media_type
        }
        img_format=""
        switch content_type
            when 'image/jpeg' then img_format='JPG'; break;
            when 'image/gif' then img_format='GIF'; break;
            when 'image/png' then img_format='PNG'; break;
        for idx,i of liste_images
          if i.nom==nom
            console.log "image deja presente"
            return false
        backend.upload_image nomEvent, nom, poster,poster_user,avatar, tweet, data,img_format, (url_wp)->  
          if url_wp!="TOO_BIG"
            console.log "image uploadée"
            param_img.url=url_wp
            param_img.signature = md5(url_wp)
            console.log 'init_twitter',param_img
            liste_images.push param_img 
            images_queue.add param_img
            #chatroomNamespace.emit 'add_img',param_img
            console.log 'media:'+ nom
    if media_type == 'video'
      url_o = url_parser.parse entities.urls[0].expanded_url ,  true , true
      switch site
        when 'youtube.com' then nom = url_o.query.v
        when 'vimeo.com' then nom = url_o.pathname.split('/')[..].pop()
        when 'vine.co' then nom = url_o.pathname.split('/')[..].pop()
        else return false
      console.log   'init_twitter/1',url_o
      console.log   'init_twitter/2',url_o.query
      param_img={
        'nom' : nom, 
        'poster':poster,
        'poster_user':poster_user,
        'avatar':avatar,
        'tweet':replaceURLWithHTMLLinks tweet
        'media_type' : media_type
      }
      for idx,i of liste_images
        if i.nom==nom
          console.log "video deja presente"
          return false
      get_thumbnail  site,  entities.urls[0].expanded_url , (url_thumbnail)->
        param_img.url_thumbnail=url_thumbnail
        backend.upload_video nomEvent, nom, poster,poster_user,avatar, tweet, url, (url_wp)->  
        param_img.url=url
        param_img.signature = md5(url)
        param_img.site = site
        console.log 'init_twitter/param_img',param_img
        liste_images.push param_img 
        images_queue.add param_img
        #chatroomNamespace.emit 'add_img',param_img
        console.log 'media:'+ nom


  twitter.on 'start', () -> 
    chatroomNamespace.emit "twitter_start"


  twitter.on 'error', (data) -> 
    chatroomNamespace.emit "errorTwitter",data


  twitter.on 'heartbeat', (data) -> 
    console.log  "Twitter stream is alive"
    chatroomNamespace.emit 'heartbeat_twitter'

  twitter.on 'close', (data) -> 
    console.log  "Twitter stream is closed :",data
    chatroomNamespace.emit 'twitter_close'
    twitter = new Twitter(auth_twitter) 
    init_twitter twitter


init_twitter twitter