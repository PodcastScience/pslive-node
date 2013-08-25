jQuery = $(document).ready 


jQuery ->
  socket = io.connect('http://localhost:3000')

  socket.emit('test')

  $('#loginform').submit( (e) -> 
  	e.preventDefault()
  	socket.emit('login', {
  		username: $('#username').val(),
  		mail: $('#mail').val()
  		})
  	)

  socket.on 'newuser', (user) ->
    html_to_append = "<img src=\"#{user.avatar}\" id=\"#{user.id}\">" 
    $('#members-list').append(html_to_append)

  socket.on 'logged', ->
    $('#login').fadeOut()

  socket.on 'disuser', (user) ->
    id_to_find = "\##{user.id}"
    $('#members-list').find(id_to_find).fadeOut()