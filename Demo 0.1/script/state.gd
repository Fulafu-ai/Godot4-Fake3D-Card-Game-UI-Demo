class_name State
extends Node

signal transition_requested(from: State, to: int)

var state: int


func enter() -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
