$(document).ready ->

  # $(window).konami
  #     cheat: ->
  #       alert "C'est pas bien de diviser par zéro..."

  connect_url = "/"
  id_connexion= false
  username=""
  email=""
  last_msg_id = false
  last_msg_txt = ""  
  userlist = []
  socket = io.connect(connect_url)
  msg_template = $('#message-box').html()
  $('#message-box li').remove()

  user_box_template = $('#user_box').html()
  $('#user_box').remove()


  highlightPseudo= (text) ->
    userref=''
    equiv=[]
    userlist.sort((a,b)-> b.length-a.length)
    i=0
    for u in userlist 
      i++
      equiv[i]=u
      pattern=RegExp("@("+u+")","ig")
      text=text.replace(pattern,"@"+i)
      console.log text
    for val,idx in equiv 
      pattern=RegExp("@("+idx+")","ig")
      unless val==username
        text=text.replace(pattern,"@"+val)
      else
        text=text.replace(pattern,"<span class='mypseudo'>@"+val+"</span>")
      console.log  text
    return text


  unless window.location.pathname=='/admin'
    #console.log('Envoi du Hello initial') 
    socket.emit('Hello','')
    
  socket.on 'Olleh', (id) ->
    console.log('Olleh recu *'+id+'*')
    id_connexion=id
    if( username != "" && email != "")
      send_login()

  socket.on 'update_compteur', (connected) ->
    str=""
    if (connected.connecte==0)
      str+="<span class='connectes'>"+connected.connecte+"</span> auditeur connecté"
    if (connected.connecte==1)
      str+="<span class='connectes'>"+connected.connecte+"</span> auditeur connecté"
    if (connected.connecte>1)
      str+="<span class='connectes'>"+connected.connecte+"</span> auditeurs connectés"
    if (connected.cache==1)
        str+="<br>(plus <span class='caches'>"+connected.cache+"</span> qui se cache)"
    if (connected.cache>1)
        str+="<br>(plus <span class='caches'>"+connected.cache+"</span> qui se cachent)"
    $('.nb-connected').html(str)

  # log des users
  $('#loginform').submit( (e) ->
    e.preventDefault()
    username = $('#username').val()
    email = $('#mail').val()
    send_login()
    )

  socket.on 'erreur', (message) ->
    #console.log('Erreur recu')
    $('#wrong-mail').html(message).fadeIn()


    

  # gestion des utilisateurs
  socket.on 'newuser', (user) ->
    id_to_find = "\##{user.id}"
    userlist.push(user.username)
    if($('#members-list').find(id_to_find).length == 0)
      #html_to_append = "<img src=\"#{user.avatar}\" id=\"#{user.id}\">" 
      $('#members-list').append(Mustache.render(user_box_template,user))

  socket.on 'logged', ->
    $('#login').fadeOut()
    $('#send-message').removeAttr('disabled')
    $('#send-message').css('opacity',1)
    $('#message-form').fadeIn()
    $('#message-to-send').focus()

  socket.on 'disuser', (user) ->
    id_to_find = "\##{user.id}"
    $('#members-list').find(id_to_find).fadeOut()


  # envoi de message
  envoi_nouveau_message = (e) ->
    e.preventDefault()
    last_msg_txt = $('#message-to-send').val()
    socket.emit 'nwmsg', {
      message: last_msg_txt,
      id_connexion: id_connexion
    }
    $('#message-to-send').val("")
    $('#message-to-send').focus()
    
  envoi_modif_message = (e) ->
    e.preventDefault()
    last_msg_txt = $('#message-to-send').val()
    socket.emit 'editmsg', {
      message: last_msg_txt,
      id_connexion: id_connexion
    }
    $('#message-form').off 'submit'
    $('#message-form').on 'submit',  envoi_nouveau_message
    $('#message-to-send').addClass('newmsg')
    $('#message-to-send').removeClass('editmsg')
    $('#message-to-send').val("")
    $('#message-to-send').focus()
    
  $('#message-form').on 'submit',  envoi_nouveau_message
    

  socket.on 'editmsg', (message) ->
    $('#msg_'+message.id).html(highlightPseudo message.message)
    
  socket.on 'nwmsg', (message) -> 
    flag_scrollauto=$('#messages').prop('scrollHeight')<=($('#main').prop('scrollTop')+$('#main').height())
    d=new Date();
    decalage=d.getTimezoneOffset()/60
    message.h=(parseInt(message.h)-decalage)%24;
    message.message=highlightPseudo message.message
    if last_msg_id != message.user.id
      $('#messages').append(Mustache.render(msg_template,message))
      last_msg_id = message.user.id
    else
      $(".message:last").append('<p id="msg_'+message.id+'">'+message.message+'</p>')
    if flag_scrollauto
      $('#main').animate({scrollTop: $('#messages').prop('scrollHeight')},500)


  $('#admin-form').submit( (e) ->
    e.preventDefault()
    #maj du titre
    if $('#episode-number').val()!='' && $('#episode-title').val()!=''
      socket.emit('change-title', {
        password: $('#admin-password').val(),
        number: $('#episode-number').val(),
        createEvent: $('#create-event:checked').val()=='on',
        title: $('#episode-title').val()
        })
    else
      if $('#episode-number').val()
        alert "Titre de l'épisode non renseigné"
      else
        if $('#episode-title').val()
          alert "Numero de l'épisode non renseigné"
    )


  socket.on 'new-drawings', (livedraw_iframe) ->
    $('#live-draw-frame').html(livedraw_iframe)


  socket.on 'new-title', (episode) ->
    #console.log("Nouveau Titre")
    $('#title-episode').html(episode)


    
    
  socket.on 'disconnect',() ->
    console.log("evt disconnect recu *"+id_connexion+"*")
    if id_connexion
      setTimeout(display_loginform,15000)
      $('#send-message').attr('disabled', 'disabled')
      $('#send-message').css('opacity',0.5)
      console.log("Il s'est fait jeté")
      $('#members-list li').remove()
      $('.nb-connected').html("")
      
      socket.emit('Hello',id_connexion)


  $('.rec').on 'dblclick', ->
    console.log 'Demande de Refresh'
    socket.emit 'refreshSP' 

  $(window).on 'beforeunload', ->
    console.log("il s'est barré")
    undefined if socket.emit 'triggered-beforeunload'

  send_login = () ->
    socket.emit('login', {
      username: username,
      mail: email,
      id_connexion: id_connexion
      })

  display_loginform = () ->
    if(!id_connexion)
      $('#login').fadeIn()
      $('#message-form').fadeOut()
      msg = "Damned! Vous avez été deconnecté !"
      $('#wrong-mail').html(msg).fadeIn()

  $('#reinitChatroomForm').on 'submit',  (e) ->
      e.preventDefault()
      console.log("Reinitiailisation de la chatroom")
      socket.emit('reinit_chatroom',$('#admin-password2').val())
            
  socket.on 'del_msglist', () ->
    # Message ne marchent plus apres le vidage mais remarche si on redemarre le serveur 
    console.log("Vidage de la liste des messages")
    last_msg_id=""
    $('#messages li').remove()
    
  $('input#message-to-send').on 'keydown', (e)->
    input = $('#message-to-send')
    if e.which == 38 
      e.preventDefault()
      if input.is('.newmsg')
        $('#message-form').off 'submit'
        $('#message-form').on 'submit',  envoi_modif_message
        input.addClass('editmsg')
        input.removeClass('newmsg')
        input.val(last_msg_txt)
        input[0].selectionStart = last_msg_txt.length
        input[0].selectionEnd = last_msg_txt.length
    if e.which == 40 && input.is('.editmsg')
      e.preventDefault()
      $('#message-form').off 'submit'
      $('#message-form').on 'submit',  envoi_nouveau_message
      input.addClass('newmsg')
      input.removeClass('editmsg')
      input.val("")


 
  # Gestion de la completion des nom d'utilisateur. 
  $('input#message-to-send').on 'keypress', (e)->
    char = String.fromCharCode(e.which)
    if char != ""  && e.which>32
      e.preventDefault()
      input = $('#message-to-send')[0] 
      curseur=input.selectionStart
      valeur=input.value
      #les 3 lignes qui suivent sont necessaires pour effacer l'autocompletion precedente 
      input.value=valeur.substring(0,curseur)+valeur.substring(input.selectionEnd)
      input.selectionStart=curseur
      valeur=input.value
      debut=valeur.substr(0, curseur).lastIndexOf("@")
      if  debut== -1 || debut==curseur
        input.value = insertText valeur,curseur,char 
        input.selectionStart = curseur+1
        input.selectionEnd =  curseur+1
        return 0 
      nom_saisie=valeur.substring(debut+1,curseur)+char
      pattern = new RegExp '^'+nom_saisie , 'ig'
      userref=""
      for u in userlist 
        if u.match pattern
          userref=u if userref=="" || userref.length>=u.length
      unless userref == ""
        patterncomplet = new RegExp '^'+userref , 'ig'
        complement= userref.substring(curseur-debut)
        str=valeur.substring(debut+1,curseur)+valeur.substring(curseur) 
        unless str.match patterncomplet
          input.value =  insertText valeur,curseur,char+complement
        else
          input.value =  insertText valeur,curseur,''
        input.selectionStart = curseur+1
        input.selectionEnd = complement.length+curseur+1
      else
        input.value =  insertText valeur,curseur,char
        input.selectionStart = curseur+1
        input.selectionEnd =  curseur+1  


  
  insertText = (valeur,position,texte) ->
    valeur.substring(0,position)+texte+valeur.substring(position)
 
