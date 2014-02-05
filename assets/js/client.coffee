$(document).ready ->

  # $(window).konami
  #     cheat: ->
  #       alert "C'est pas bien de diviser par zéro..."

  connect_url = "http://podcastscience.herokuapp.com"
  #connect_url = "http://localhost:3000"
  last_msg_id = false

  socket = io.connect(connect_url)
  msg_template = $('#message-box').html()
  $('#message-box').remove();

  user_box_template = $('#user_box').html()
  $('#user_box').remove();

#  socket.emit('test')
  


  socket.on 'update_compteur', (connected) ->
    $('.nb-connected').html("<span>"+connected+"</span> auditeurs <br>en ligne</h2>")


  # log des users
  $('#loginform').submit( (e) -> 
    e.preventDefault()
    socket.emit('login', {
      username: $('#username').val(),
      mail: $('#mail').val()
      })
    )

  socket.on 'error', (message) ->
    $('#wrong-mail').html(message).fadeIn()

        




  # gestion des utilisateurs
  socket.on 'newuser', (user) ->
    html_to_append = "<img src=\"#{user.avatar}\" id=\"#{user.id}\">" 
    $('#members-list').append(Mustache.render(user_box_template,user))

  socket.on 'logged', ->
    $('#login').fadeOut()
    $('#message-form').fadeIn()
    $('#message-to-send').focus()

  socket.on 'disuser', (user) ->
    id_to_find = "\##{user.id}"
    $('#members-list').find(id_to_find).fadeOut()


  # envoi de message
  $('#message-form').submit (e) ->
    e.preventDefault()
    socket.emit 'nwmsg', {
      message: $('#message-to-send').val()
    }
    $('#message-to-send').val("")
    $('#message-to-send').focus()

  socket.on 'nwmsg', (message) ->
    flag_scrollauto=$('#messages').prop('scrollHeight')<=($('#main').prop('scrollTop')+$('#main').height())
    if last_msg_id != message.user.id
      $('#messages').append(Mustache.render(msg_template,message))
      last_msg_id = message.user.id
    else  
      $(".message:last").append('<p style="font-size:small;">'+message.message+'</p>')
    if flag_scrollauto
      $('#main').animate({scrollTop: $('#messages').prop('scrollHeight')},500)


  $('#admin-form').submit( (e) -> 
    # envoi d'un iframe
    e.preventDefault()
    socket.emit('new-iframe', {
      password: $('#admin-password').val(),
      iframe: $('#iframe-value').val()
      })
    #maj du titre
    if $('#episode-number').val()!='' && $('#episode-title').val()!=''
      socket.emit('change-title', {
        password: $('#admin-password').val(),
        number: $('#episode-number').val(),
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
    $('#title-episode').html(episode)

  socket.on 'disconnect', ->
    $('#login').fadeIn()
    $('#message-form').fadeOut()  
    $('#wrong-mail').html("Damned! Vous avez été deconnecté!").fadeIn()

  $(window).on 'beforeunload', ->
    console.log("il s'est barré")
    undefined if socket.emit 'triggered-beforeunload'




