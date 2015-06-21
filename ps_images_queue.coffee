class PsImagesQueue

	delay=0	# temps minimum d'attente minimum entre 2 images en millesecondes
	queue=null
	wait=false
	pause=false
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

	remove : (signature)->
		queue=queue.filter (i)-> i.signature != signature

	send : () =>
		wait=true
		if !pause
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
		else 
			wait=false

	add: (params) =>
		console.log "ajout d'une image"
		queue= new Array() if typeof(queue)=='undefined'
		queue.push params
		this.send() if !wait && !pause

	pause: ()->
		console.log "mise en pause de la file d'attente:",!pause
		pause=!pause
		this.send() if !wait && !pause	
		return pause
	
	get_pause: ()-> return pause


		




module.exports = PsImagesQueue