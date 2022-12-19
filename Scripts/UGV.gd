extends RigidBody2D

# Constants
const TRACK_DIST_FROM_CENTER = 11 #px
const WHEEL_RADIUS = 1 # unknown
const MAX_FORCE = 100000
const PX2METER = 0.1 #1 pixel is 10cm
const ENGINE_BRAKE_COEFF = 10000
const MAX_LIN_SPEED = 3/PX2METER #m/s
const MAX_ANG_SPEED = 2 #rad/s
const GRAVITY = 9.8

# Internal Classes
class DriveForces:
	var left_track_force : float
	var right_track_force : float

class EnvironmentalForces:
	var central_force : Vector2
	var central_torque : float

class Friction extends RigidBody2D:
	var friction_x = 0.9
	var friction_y = 0.1
	var friction_ang = 0.4
	func calculateFriction() -> EnvironmentalForces:
		var env_forces = EnvironmentalForces.new()
		env_forces.central_force.x = -1*sign(linear_velocity.x)*friction_x*mass*GRAVITY
		env_forces.central_force.y = -1*sign(linear_velocity.y)*friction_y*mass*GRAVITY
		env_forces.central_torque = -1*sign(angular_velocity)*friction_ang*mass*GRAVITY*TRACK_DIST_FROM_CENTER
		return env_forces
	
class EngineBrake:
	var braking_coefficient : float
	
class UGVController:
	var driveForces : DriveForces
	var engineBrake : EngineBrake
	func calculateUGVDynamics() -> DriveForces:
		
		return driveForces
		

# Class variables
var target_velocity = Vector2()
var frictionForces : Friction
var ugv_controller : UGVController

func velocity_blender():
	pass

func cmd_vel_to_lr(_velocity : Vector2) -> Vector2:
		#convert cmd_vel to individual track speeds
		var lr_rpm = Vector2()
		var lin_vel = _velocity.x
		var ang_vel = _velocity.y
		lr_rpm.x = (lin_vel - ang_vel*TRACK_DIST_FROM_CENTER*PX2METER)/WHEEL_RADIUS
		lr_rpm.y = (lin_vel + ang_vel*TRACK_DIST_FROM_CENTER*PX2METER)/WHEEL_RADIUS
		return lr_rpm


func add_force_local(pos: Vector2, force: Vector2):
	var pos_local = self.transform.basis_xform(pos)
	var force_local = -self.transform.basis_xform(force) 
	self.add_force(pos_local, force_local)
	
func get_input():
	if Input.is_action_pressed("forward"):
		target_velocity.x = MAX_LIN_SPEED
	if Input.is_action_pressed("backward"):
		target_velocity.x = -MAX_LIN_SPEED
	if Input.is_action_pressed("left"):
		target_velocity.y = MAX_ANG_SPEED
	if Input.is_action_pressed("right"):
		target_velocity.y = -MAX_ANG_SPEED

func _ready():
	ugv_controller = UGVController.new()
	ugv_controller.driveForces = DriveForces.new()
	frictionForces = Friction.new()
	ugv_controller.engineBrake = EngineBrake.new()
	ugv_controller.engineBrake.braking_coefficient = 1000

func _process(delta):
	get_input()

func _physics_process(delta):
	# Zero current forces
	applied_force = Vector2()
	applied_torque = 0
	# Calculate current forces
	var friction_forces = frictionForces.calculateFriction()
	add_force(Vector2(), friction_forces.central_force)
	add_torque(friction_forces.central_torque)
#	add_force_local(Vector2(-right_track_distance,0), Vector2(0,track_forces.x)) #left
#	add_force_local(Vector2(right_track_distance,0), Vector2(0,track_forces.y)) #right
