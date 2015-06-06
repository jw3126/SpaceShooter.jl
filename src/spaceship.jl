abstract SpaceShip <: GameObject

type PlayerShip <: SpaceShip
	sprite::Sprite
	speed::Real
	angle::Real
	health::Int
	cooldown_clock::Clock
	color::String
	keys::Array{Int}
	healthbar::RectangleShape
end

function PlayerShip(texture_name, keys; start_pos = Vector2f(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2), start_rot = 0)
	sprite = Sprite()
	texture = manager.textures[texture_name]
	set_texture(sprite, texture)
	set_origin(sprite, Vector2f(get_size(texture).x / 2, get_size(texture).y / 2))
	set_position(sprite, start_pos)
	scale(sprite, Vector2f(X_SCALE, Y_SCALE))

	color = ""
	if Base.contains(texture_name, "blue")
		color = "Blue"
	elseif Base.contains(texture_name, "red")
		color = "Red"
	elseif Base.contains(texture_name, "green")
		color = "Green"
	end

	healthbar = RectangleShape()
	set_fillcolor(healthbar, eval(parse("SFML.$(lowercase(color))")))

	PlayerShip(sprite, 0, start_rot, 10, Clock(), color, keys, healthbar)
end

function update(ship::SpaceShip, dt)
	handle_keys(ship, dt)
	update_pos(ship, dt)
end

function handle_keys(ship::PlayerShip, dt)
	if is_key_pressed(ship.keys[1])
		ship.speed += SHIP_ACCELERATION * dt
	elseif is_key_pressed(ship.keys[2])
		ship.speed -= SHIP_ACCELERATION * dt
	else
		if ship.speed > 0
			ship.speed -= SHIP_ACCELERATION * dt
		elseif ship.speed < 0
			ship.speed += SHIP_ACCELERATION * dt
		end
	end

	if is_key_pressed(ship.keys[3])
		ship.angle -= SHIP_ROTATE_SPEED * dt
	elseif is_key_pressed(ship.keys[4])
		ship.angle += SHIP_ROTATE_SPEED * dt
	end

	if is_key_pressed(ship.keys[5])
		shoot_laser(ship)
	end

	ship.speed = clamp(ship.speed, -MAX_SHIP_SPEED, MAX_SHIP_SPEED)
end

function shoot_laser(ship::SpaceShip)
	if (get_elapsed_time(ship.cooldown_clock) |> as_seconds) > SHOT_COOLDOWN
		restart(ship.cooldown_clock)
		l = Laser("laser$(ship.color)01", get_position(ship.sprite))
		l.angle = ship.angle
		push!(lasers::Array{Laser}, l)

		sound = Sound(manager.sound_effects["sfx_laser$(rand(1:2))"])
		play(sound)
	end
end

function update_pos(ship::SpaceShip, dt)
	wrap_position(ship.sprite)

	velocity = Vector2f(ship.speed * cosd(ship.angle - 90) * dt * X_SCALE, ship.speed * sind(ship.angle - 90) * dt * Y_SCALE)
	set_rotation(ship.sprite, ship.angle)
	move(ship.sprite, velocity)

	size = get_globalbounds(ship.sprite)
	pos = get_position(ship.sprite)
	set_position(ship.healthbar, Vector2f(pos.x - size.width / 2, pos.y - size.height / 2 - 10 * Y_SCALE))
end

function laser_collision(ship::SpaceShip, laser::Laser)
	if ship.color != laser.color
		lose_health(ship, 1)
		if ship.health <= 0
			add_explosion(get_position(ship.sprite))
			die(ship)
		end
		add_explosion(get_position(laser.sprite))
		die(laser)
	end
end

function asteroid_collision(ship::SpaceShip, asteroid::Asteroid)
	lose_health(ship, 3)
	if ship.health <= 0
		add_explosion(get_position(ship.sprite))
		die(ship)
	end
	add_explosion(get_position(asteroid.sprite))
	die(asteroid)
end

function lose_health(ship::SpaceShip, amount)
	ship.health -= amount
	set_size(ship.healthbar, Vector2f(ship.health * 10 * X_SCALE, 10 * Y_SCALE))
end

function die(obj::GameObject)
	index = find(game_objects::Array{GameObject} .== obj)
	if length(index) > 0
		splice!(game_objects::Array{GameObject}, index[1])
	end
end

function draw(window, ship::SpaceShip)
	draw(window, ship.healthbar)
	draw(window, ship.sprite)
end
