extends CharacterBody2D

# Combat system variables
var enemy_in_attack_range = false
var boss_in_attack_range = false
var ghost_in_attack_range = false
var witch_in_attack_range = false
var enemy_attack_cooldown = true
var helaing_cooldown = false
var enemy = null

var player_alive = true
var attack_in_progress = false
var last_input = null

var is_dialog_active = false

signal new_player_level(level)
signal has_gold(gold)

var death_sound = true

#Player status variables
var health = 100
var experience = 0
var gold = 0
var level = 1
var levelup = 0
var maxxp = 100
var maxhealth = 100
#UI
var progress = 0

# General movement variables
const SPEED = 300
var velocity_vector = Vector2.ZERO
var anim_sprite: AnimatedSprite2D  # Reference to the AnimatedSprite2D node

func _ready():
	anim_sprite = $AnimatedSprite2D # Get a reference to the AnimatedSprite2D node
	anim_sprite.play("front_walk")
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
func _physics_process(delta):

	if(gold>=1800):
		has_gold.emit(gold)
	
	if(helaing_cooldown):
		$Camera2D/CanvasLayer/UI/status/HealingCooldown.value = progress+$healing_cooldown.time_left
	else:
		$Camera2D/CanvasLayer/UI/status/HealingCooldown.value = 0
	if(player_alive and is_dialog_active==false):
		if(attack_in_progress):
			attack_movement(delta)
		else:
			player_movement(delta) 
	elif (player_alive):
		anim_sprite.play("idle")

	enemy_attack()
	set_player_status()
	
	if health <= 0:
		player_alive = false  # Player dies from too much damage
		health = 0
		if(death_sound):
			$DeathSound.play()
			death_sound = false
		anim_sprite.play("death_animation")
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
		print("Game over, you died!")
		#self.queue_free()
		
	
func player_movement(delta):
	# Reset the velocity vector before checking input
	velocity_vector = Vector2.ZERO
	
	
	
# Basic movement statements

	var animation_chosen = false	
	

	if Input.is_action_pressed("ui_right"):
	
		velocity_vector.x += SPEED
		last_input = "ui_right";
		anim_sprite.play("right_walk")
		animation_chosen = true
	if Input.is_action_pressed("ui_left"):
	
		velocity_vector.x -= SPEED
		last_input = "ui_left";
		anim_sprite.play("left_walk")
		animation_chosen = true
	if Input.is_action_pressed("ui_down"):
		velocity_vector.y += SPEED
		last_input = "ui_down";
		if(animation_chosen==false):
		
			anim_sprite.play("front_walk")
	if Input.is_action_pressed("ui_up"):
		velocity_vector.y -= SPEED
		last_input = "ui_up";
		if(animation_chosen==false):
		
			anim_sprite.play("back_walk")

	velocity = velocity_vector  # Set the character's velocity based on the input

	if velocity_vector == Vector2.ZERO:
		anim_sprite.stop()  # Stop the animation when no movement input
	
	if Input.is_action_pressed("heal"):
		if(helaing_cooldown==false):
			heal()
	
	if Input.is_action_just_pressed("attack"):
		Global.player_current_attack = true
		attack_in_progress = true
		# Add an animated sprite for attacks here
		$deal_attack_timer.start()
		
	move_and_slide()
	
func attack_movement(delta):
	anim_sprite = $AnimatedSprite2D # Get a reference to the AnimatedSprite2D node
	if(last_input=="ui_right"):
		anim_sprite.play("attack_right")
	if(last_input=="ui_left"):
		anim_sprite.play("attack_left")
	if(last_input=="ui_down"):
		anim_sprite.play("attack_down")
	if(last_input=="ui_up"):
		anim_sprite.play("attack_up")

func set_player_status():
	set_health_bar()
	set_experience_bar()
	check_xp()
	set_gold_amount()
	set_level()



func set_health_bar():
	$Camera2D/CanvasLayer/UI/StatusMenu/HealthBar/HPBar.value = health
	$Camera2D/CanvasLayer/UI/StatusMenu/HealthBar/HPBar.max_value = maxhealth
	
func set_experience_bar():
	$Camera2D/CanvasLayer/UI/StatusMenu/XPBar/XPBar.value = experience

func set_gold_amount():
	$Camera2D/CanvasLayer/UI/Gold/GoldAmountLabel.text = str(gold)

	
func set_level():
	$Camera2D/CanvasLayer/UI/Levelup/Label.text = str(level)


func _on_player_hitbox_body_entered(body):
	
	if body.has_method("enemy"):
		enemy_in_attack_range = true
	if body.has_method("boss"):
		boss_in_attack_range = true
	if body.has_method("witch"):
		witch_in_attack_range = true
	if body.has_method("ghost"):
		ghost_in_attack_range = true
	enemy = body
	
func _on_player_hitbox_body_exited(body):
	if body.has_method("enemy"):
		enemy_in_attack_range = false
	if body.has_method("boss"):
		boss_in_attack_range = false
	if body.has_method("witch"):
		witch_in_attack_range = false
	if body.has_method("ghost"):
		ghost_in_attack_range = false
	enemy = null

func player():
	pass

func enemy_attack():
	if enemy_in_attack_range and enemy_attack_cooldown and player_alive == true:
		var attackPower = 10
		if(boss_in_attack_range):
			if(enemy.death!=true):
				attackPower = 55
			else:
				attackPower = 0
		elif(ghost_in_attack_range):
			attackPower = 40
		elif(witch_in_attack_range):
			attackPower = 20
		if(attackPower>0):
			spawn_dmgIndicator(attackPower)
			health = health - attackPower
			$DamageSound.play()
			enemy_attack_cooldown = false
			$attack_cooldown.start() 
			print("player health is ", health)


func _on_attack_cooldown_timeout(): 
	enemy_attack_cooldown = true
	



func _on_deal_attack_timer_timeout():
	$deal_attack_timer.stop()
	Global.player_current_attack = false
	attack_in_progress = false


func spawn_effect(EFFECT: PackedScene, effect_position: Vector2 = global_position, offset: Vector2 = Vector2.ZERO):
		if EFFECT:
			
			var effect = EFFECT.instantiate()
			effect.global_position = effect_position + offset  # Applying offset to the position
			get_tree().current_scene.add_child(effect)
			
			return effect 
			
func spawn_dmgIndicator(damage: int):
	var INDICATOR_DAMAGE = preload("res://ui/damage_indicator.tscn")
	var indicator = spawn_effect(INDICATOR_DAMAGE, global_position, Vector2(150, -40))
	if indicator:
		indicator.label_node.text =  "- " + str(damage)

func spawn_goldIndicator(damage: int):
	var INDICATOR_DAMAGE = preload("res://ui/gold_indicator.tscn")
	var indicator = spawn_effect(INDICATOR_DAMAGE, global_position, Vector2(150, -40))
	if indicator:
		indicator.label_node.text = str(damage) + " GOLD"
		
func spawn_xpIndicator(damage: int):
	var INDICATOR_DAMAGE = preload("res://ui/xp_indicator.tscn")
	var indicator = spawn_effect(INDICATOR_DAMAGE, global_position, Vector2(150, -40))
	if indicator:
		indicator.label_node.text = str(damage) + " XP"

func spawn_healingIndicator(healing: int):
	var INDICATOR_DAMAGE = preload("res://ui/healing_indicator.tscn")
	var indicator = spawn_effect(INDICATOR_DAMAGE, global_position, Vector2(150, -40))
	if indicator:
		indicator.label_node.text = "+ " + str(healing)

func get_exp(amount):
	spawn_xpIndicator(amount)
	experience += amount
	
func get_gold(amount):
	spawn_goldIndicator(amount)
	gold += amount
	
func heal():
		health += 10*level
		spawn_healingIndicator(10*level)
		$healing_cooldown.start()
		helaing_cooldown = true
		if(health>maxhealth):
			health = maxhealth

func check_xp():
	if(experience>=maxxp):
		level += 1
		maxhealth +=10
		new_player_level.emit(level)
		experience = experience-maxxp




func _on_healing_cooldown_timeout():
	helaing_cooldown = false
func _on_dialogue_ended(_resource: DialogueResource):
	is_dialog_active = false

func sword_bought():
	gold = gold - 1800
	for n in 5:
		new_player_level.emit(1)
	
func _on_npc_dialogue_started():
	is_dialog_active = true;
