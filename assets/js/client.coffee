jQuery = $(document).ready 


jQuery ->
  socket = io.connect('http://localhost:3000')
  msg_template = $('#message-box').html();
  $('#message-box').remove();

  socket.emit('test')


  # log des users
  $('#loginform').submit( (e) -> 
  	e.preventDefault()
  	socket.emit('login', {
  		username: $('#username').val(),
  		mail: $('#mail').val()
  		})
  	)


  # gestion des utilisateurs
  socket.on 'newuser', (user) ->
    html_to_append = "<img src=\"#{user.avatar}\" id=\"#{user.id}\">" 
    $('#members-list').append(html_to_append)

  socket.on 'logged', ->
    $('#login').fadeOut()
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
    $('#messages').append(Mustache.render(msg_template,message))
