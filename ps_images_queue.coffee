class PsImagesQueue

	delay=0	# temps minimum d'attente minimum entre 2 images en millesecondes
	queue=null
	wait=false
	sockets=null
	me=@

	constructor: (params) ->
		sockets=params.sockets
		delay=params.delay
		wait=false
		console.log "Init de la file d'attente des images avec un delai de "+delay
		queue= new Array()

	end_queue : () =>
		console.log "end_queue",queue
		if typeof(queue)=='undefined' || queue.length==0
			wait=false
		else
			this.send()


	send : () =>
		wait=true
		console.log "Envoi d'une image"
		param_img = queue.shift()
		sockets.emit 'add_img',param_img
		console.log "Image envoyé"
		if queue.length==0
			console.log "Fin de la file d'attente"
			setTimeout this.end_queue ,delay
		else
			console.log delay+" ms d'attente avant de la prochaine image"
			setTimeout( this.send,delay)

	add: (params) =>
		console.log "ajout d'une image"
		queue= new Array() if typeof(queue)=='undefined'
		queue.push params
		this.send() if !wait
		




module.exports = PsImagesQueue