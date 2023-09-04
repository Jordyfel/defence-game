class_name SignalCombiner
extends RefCounted



signal completed(data: Dictionary)



func _init(signals: Array[Signal]) -> void:
	for s in signals:
		_extract_data(s)


func _extract_data(s: Signal) -> void:
	while true:
		var data = await s
		completed.emit({"source": s, "data": data})
