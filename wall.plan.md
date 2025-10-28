# Wall-Slide verlangsamen und Wall-Jump mit seitlichem Push in `features/player/Player.gd`

Der Wall-Slide beschleunigt aktuell, da zur normalen Gravitation zusätzlich `GRAVITY_WALL` addiert wird. Außerdem existieren Variablen für Wall-Jump (`WALL_JUMP_PUSH_FORCE`, `wall_contact_coyote`, `wall_jump_lock`), werden aber nicht überall genutzt. Wir implementieren:

- Einen langsamen Wall-Slide via Max-Fallgeschwindigkeit (Clamp), keine Zusatzbeschleunigung.
- Einen echten Wall-Jump, der horizontal von der Wand weg pusht und Eingaben kurzzeitig sperrt.

Problemstellen (Ist-Zustand):

```95:101:/Users/flolle/Documents/Game Dev/fjord-n-fury/features/player/Player.gd
	# GRAVITY:
	if not is_on_floor():
		velocity.y += GRAVITY * _delta
		AirborneLastFrame = true
	elif AirborneLastFrame:
		PlayLandVFX()
```

```159:175:/Users/flolle/Documents/Game Dev/fjord-n-fury/features/player/Player.gd
	# Wall-Slide:
	# Man ist NICHT auf dem Boden, man fällt, man ist an der Wand und man bewegt sich zur Wand:
	if !is_on_floor() and velocity.y > 0 and is_on_wall() and velocity.x != 0:
		print("Slide Wall")
		look_dir_x = sign(velocity.x)
		wall_contact_coyote = WALL_CONTACT_COYOTE_TIME #reset coyote
		velocity.y = min(velocity.y, WALL_SLIDE_MAX_SPEED)
	else:
		wall_contact_coyote -= _delta
```

```133:137:/Users/flolle/Documents/Game Dev/fjord-n-fury/features/player/Player.gd
	# Laufen:
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
```

```139:147:/Users/flolle/Documents/Game Dev/fjord-n-fury/features/player/Player.gd
	if jump_buffer_timer > 0.0 and not is_on_floor() and wall_contact_coyote > 0.0:
		animated_sprite_2d.play("Jump")
		velocity.y = JUMP_VELOCITY
		# Weg von der Wand pushen
		velocity.x = -look_dir_x * WALL_JUMP_PUSH_FORCE
		wall_jump_lock = WALL_JUMP_LOCK_TIME
```

## Änderungen

1. Wall-Slide verlangsamen (Clamp statt Zusatzbeschleunigung)

- Konstante (bereits vorhanden):

```gdscript
const WALL_SLIDE_MAX_SPEED: int = 60
```

- Im Wall-Slide-Block bleibt das Clamping bestehen.

2. Wall-Jump mit horizontalem Push und klarer Input-Sperre

- Im Wall-Jump-Zweig Buffer/Coyote/Jumps zurücksetzen, damit keine Mehrfachsprünge passieren und der Coyote-Fenster endet:

```gdscript
if jump_buffer_timer > 0.0 and not is_on_floor() and wall_contact_coyote > 0.0:
	animated_sprite_2d.play("Jump")
	velocity.y = JUMP_VELOCITY
	velocity.x = -look_dir_x * WALL_JUMP_PUSH_FORCE
	wall_jump_lock = WALL_JUMP_LOCK_TIME
	jump_buffer_timer = 0.0
	jumps_left = max(jumps_left - 1, 0)
	wall_contact_coyote = 0.0
```

- Die horizontale Eingabe nur verarbeiten, wenn kein Lock aktiv ist. Ersetze den Laufen-Block durch:

```gdscript
if wall_jump_lock <= 0.0:
	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
```

- Und den Lock-Timer weiterhin pro Frame abbauen (bereits vorhanden):

```gdscript
if wall_jump_lock > 0.0:
	wall_jump_lock -= _delta
```

Optional

- Während `wall_jump_lock` aktiv ist, könnte man `velocity.x` leicht dämpfen, wenn der Push zu stark wirkt (z. B. `velocity.x *= 0.99`), oder die Lock-Zeit/Push-Stärke feinjustieren (`WALL_JUMP_LOCK_TIME`, `WALL_JUMP_PUSH_FORCE`).

