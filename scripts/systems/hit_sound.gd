class_name HitSound
## يولد نقرات ضربات قصيرة بترددات مختلفة حسب ما خلف الجدار.


static func make(frequency: float, duration := 0.12) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(duration * rate)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(rate)
		var decay := 1.0 - float(i) / float(frames)
		var sample := int(sin(TAU * frequency * t) * 32767.0 * decay * 0.5)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	return stream
