class_name SignalCombiner
extends RefCounted



signal completed_any(data: Dictionary)
signal completed_all(data: Dictionary)

var signals: Array[Signal]
var signal_data: Dictionary



func _init(new_signals: Array[Signal]) -> void:
	signals =  new_signals
	for s in signals:
		_extract_data(s)


func _extract_data(s: Signal) -> void:
	var data = await s
	_on_signal_emitted(s, data)


func _on_signal_emitted(s: Signal, data: Variant) -> void:
	completed_any.emit({"source": s, "data": data}) # ?
	signal_data[s] = data
	signals.erase(s)
	if signals.is_empty():
		completed_all.emit(signal_data)
