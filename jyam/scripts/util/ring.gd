class_name Ring extends RefCounted

var _head: int = 0
var _tail: int = 0
var _count: int = 0
var _buffer: Array

var count: int:
	get:
		return self._count
	set(_value):
		assert(false, "cannot set count directly")

# capacity
var cap: int:
	get:
		return self._buffer.size()
	set(_value):
		assert(false, "cannot set cap directly")

func _init(size: int):
	var buf = Array()
	buf.resize(size)
	self._buffer = buf
	self._head = 0
	self._tail = 0
	self._count = 0
	
func enqueue(o: Variant) -> bool:
	if self._count == self.cap:
		return false
	
	var slot = (self._head + self._count) % self.cap
	assert(self._buffer[slot] == null, "oops buffer slot {0} is {1} not null".format(
		[slot, self._buffer[slot]]))
	self._buffer[slot] = o
	self._count += 1
	return true
	
func dequeue() -> Variant:
	if self._count == 0:
		return null
		
	var o = self._buffer[self._head]
	assert(o != null, "oops head {0} is null".format([self._head]))
	self._buffer[self._head] = null
	self._head = (self._head + 1) % self.cap
	self._count -= 1
	return o
	
static func _unittest():
	var r = Ring.new(5)
	var a = Array()
	for i in range(r.cap):
		a.append(RefCounted.new())
	
	var ref_counts = func(items: Array):
		var counts = []
		for v in items:
			# subtract 1 for v's ref
			counts.append(v.get_reference_count() - 1)
		return counts
		
	var refill = func(items: Array):
		var counts = ref_counts.call(items)
		var i = 0
		for val in items:
			assert(r.enqueue(val))
			# add 1 for val's ref and 1 for enqueue
			assert(val.get_reference_count() == counts[i] + 1 + 1,
				"enqueue didn't ref")
			i += 1
	
	var dequeue_some = func(check_array: Array):
		var counts = ref_counts.call(check_array)
		for i in range(0, check_array.size()):
			var val = r.dequeue()
			assert(val == check_array[i], "FIFO failed")
			# add 1 for val's ref, subtract 1 for dequeue
			assert(val.get_reference_count() == counts[i] + 1 - 1,
				"dequeue didn't deref")
			assert(r.cap == a.size())
	
	refill.call(a)
	assert(r.count == a.size())
	
	# enqueue when full fails
	assert(!r.enqueue(RefCounted.new()))
	assert(r.count == a.size())
	
	dequeue_some.call(a)
	assert(r.count == 0)
	# dequeue when empty returns null
	assert(r.dequeue() == null)
	assert(r.count == 0)
	refill.call(a)

	var check = a.slice(0,2)
	dequeue_some.call(check)
	
	# make sure enqueue wrapping works
	check = a.slice(2, a.size())
	for i in range(2):
		var val = RefCounted.new()
		check.append(val)
		assert(r.enqueue(val))
	dequeue_some.call(check)
	
	check = a.slice(2, a.size())
	refill.call(check)
	dequeue_some.call(check)
	assert(r.dequeue() == null)
	
	check.clear()
	for val in a:
		assert(val.get_reference_count() == 2)
