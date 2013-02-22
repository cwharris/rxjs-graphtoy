springs = []

physics = new Physics
particles = []

makeNode = (stats) ->
	# console.log stats
	particle = new Particle
	particles.push particle

	angle = (stats.spoke / stats.numSpokes) * Math.PI * 2
	x = Math.cos angle
	y = Math.sin angle
	angle2 = (3/stats.numSpokes) * Math.PI * 2
	x2 = Math.cos angle + angle2
	y2 = Math.sin angle + angle2
	particle.pos = new Vector(x, y)
		.scale(100 * (stats.level + 1))
		.add(new Vector(720, 350))
		.add new Vector(x2, y2).scale(stats.i * 10)
	physics.particles.push particle
	particle

makeLink = (a, b) ->
	spring = new Spring a, b, 40, 0.15
	springs.push spring
	physics.springs.push spring
	spring

makeSpoke = (level, spoke, numSpokes, numLevels, fNode, fLink) ->

	# console.log 'making new spoke', level

	stats = 
		level: level


	nodes = (fNode(level: level, spoke: spoke, i:_, numLevels:numLevels, numSpokes:numSpokes) for _ in [0..level])

	for i in [0...nodes.length-1]
		a = nodes[i]
		b = nodes[(i + 1) % nodes.length]
		fLink a, b

	nodes: 		nodes
	firstNode: 	nodes[0]
	lastNode: 	nodes[nodes.length - 1]

makeGraph = (numSpokes, numLevels, fNode, fLink) ->
	# console.log 'making new graph'

	parentSpokes = (null for _ in [0...numSpokes])

	for level in [0...numLevels]
		# make spokes for this level
		# console.log 'making new level'
		spokes = (makeSpoke level, _, numSpokes, numLevels, fNode, fLink for _ in [0...numSpokes])

		# link spokes together
		for spokeA, i in spokes
			spokeB = spokes[(i + 1) % spokes.length]
			fLink spokeA.lastNode, spokeB.firstNode

			if parentB = parentSpokes[(i + 1) % spokes.length]
				fLink spokeA.lastNode, parentB.firstNode

			if parentA = parentSpokes[i]
				for nodeA, i in parentA.nodes
					nodeB = spokeA.nodes[i]
					nodeC = spokeA.nodes[i+1]
					fLink nodeA, nodeB
					fLink nodeA, nodeC
				# for a, i in parentA.nodes


		parentSpokes = spokes
			

$ ->

	$window = $ window

	$canvas = $ 'canvas'
	ctx = $canvas[0].getContext '2d'

	# console.log particles.length, particles
	# console.log springs.length, springs

	$layers = $('<input type="text">').appendTo('body')
	$spokes = $('<input type="text">').appendTo('body')

	numLayers = new Rx.BehaviorSubject 3
	numSpokes = new Rx.BehaviorSubject 6

	# makeGraph numLayers, numSpokes, makeNode, makeLink

	$layers.onAsObservable('keyup')
		.select((e) -> $(e.target).val())
		.distinctUntilChanged()
		.select((text) -> parseInt text)
		.where((n) -> isFinite(n) and n > 0 and n <= 12)
		.subscribe (n) ->
			numLayers.onNext n

	$spokes.onAsObservable('keyup')
		.select((e) -> $(e.target).val())
		.distinctUntilChanged()
		.select((text) -> parseInt text)
		.where((n) -> isFinite(n) and n > 0 and n <= 100)
		.subscribe (n) ->
			numSpokes.onNext n

	numLayers.combineLatest(numSpokes, (numLayers, numSpokes)-> numLayers: numLayers, numSpokes: numSpokes).subscribe (x) ->
		particles = []
		springs = []
		physics.particles = []
		physics.springs = []
		makeGraph x.numSpokes, x.numLayers, makeNode, makeLink
		console.log springs.length

	$(document).onAsObservable('mousemove')
		# .sample(100)
		.select((e) -> new Vector e.clientX, e.clientY)
		.select((mousePos) ->
			combos = _.map particles, (particle) ->
				# console.log particle
				particle: particle
				distance: particle.pos.dist mousePos
			combos = _.sortBy combos, (combo) ->
				combo.distance
			)

		.subscribe (combos) ->
			_.each combos, (combo, i) ->
				if i is 0
					combo.particle.nearMouse = true
					combo.particle.veryNearMouse = combo.distance < 15
				else
					combo.particle.nearMouse = false
					combo.particle.veryNearMouse = false
				# console.log combo.particle.nearMouse

	$(document).onAsObservable('click')
		.select((e) -> new Vector e.clientX, e.clientY)
		.select((mousePos) ->
			combos = _.map particles, (particle) ->
				# console.log particle
				particle: particle
				distance: particle.pos.dist mousePos

			combos = _.sortBy combos, (combo) ->
				combo.distance

			combos[0]
		)
		.subscribe (combo) ->
			if combo.distance < 15
				console.log 'click'
				physics.particles = particles = _.filter particles, (particle) -> particle != combo.particle
				physics.springs = springs = _.filter springs, (spring) ->
					spring.p1 != combo.particle and spring.p2 != combo.particle
				# _.filter 


	update = ->

		physics.step()

		ctx.clearRect 0, 0, $window.width(), $window.height()

		for spring in springs
			p1 = spring.p1
			p2 = spring.p2

			ctx.strokeStyle = 'rgba(0, 0, 0, 0.25)'
			ctx.beginPath()
			ctx.moveTo p1.pos.x, p1.pos.y
			ctx.lineTo p2.pos.x, p2.pos.y
			ctx.stroke()

		for particle in particles
			ctx.strokeStyle = 'none'
			if particle.nearMouse
				if particle.veryNearMouse
					ctx.fillStyle = 'rgba(0,0,255,0.5)'
				else
					ctx.fillStyle = 'rgba(255,0,0,0.5)'
			else
				ctx.fillStyle = 'rgba(0,0,0,0.25)'

			ctx.beginPath()
			ctx.arc(particle.pos.x, particle.pos.y, particle.mass * 15, 0, Math.PI * 2)
			ctx.fill()
			ctx.beginPath()
			ctx.fillStyle = 'rgba(255,255,255,1)'
			ctx.arc(particle.pos.x, particle.pos.y, particle.mass * 10, 0, Math.PI * 2)
			ctx.fill()

		# ctx.strokeStyle = '#000'
		# ctx.beginPath()
		# ctx.moveTo 0, 0
		# ctx.lineTo 250, 250
		# ctx.stroke()

		requestAnimationFrame update

	update()

