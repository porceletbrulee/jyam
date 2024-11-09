class_name MinHeap extends RefCounted

var _count: int
var _heap: Array
var _less_than: Callable

var count: int:
	get:
		return self._count
	set(_value):
		assert(false, "cannot set count directly")

# capacity
var cap: int:
	get:
		return self._heap.size()
	set(_value):
		assert(false, "cannot set cap directly")

# cmp: should return -1 if left < right, 0 if left == right, 1 if left > right
func _init(less_than: Callable):
	self._heap = Array()
	self._heap.resize(32)
	self._count = 0
	self._less_than = less_than

func push(value) -> bool:
	if self._count == self.cap:
		assert(self.cap < 4096, "heap too big, leak?")
		self._heap.resize(self._heap.size() * 2)
	
	var i = self._count
	self._heap[i] = value
	self._count += 1
	self._heapify_up(i)
	return true

func peek_root():
	if self._count == 0:
		return null
		
	return self._heap[0]

func pop_root():
	if self._count == 0:
		return null

	var root = self._heap[0]
	var last_index = self._count - 1
	self._heap[0] = self._heap[last_index]
	self._heap[last_index] = null  # ensure deref
	self._count -= 1
	self._heapify_down(0)
	return root

func _parent(index: int) -> int:
	assert(index > 0)
	@warning_ignore("integer_division") return (index - 1) / 2

func _left_child(index: int) -> int:
	return (2 * index) + 1

func _right_child(index: int) -> int:
	return (2 * index) + 2

func _swap(i: int, j: int):
	var v = self._heap[i]
	self._heap[i] = self._heap[j]
	self._heap[j] = v

func _heapify_up(index: int):
	while index > 0:
		var curr = self._heap[index]
		var parent_index = self._parent(index)
		var parent = self._heap[parent_index]
		
		if !self._less_than.call(curr, parent):
			break
			
		self._swap(index, parent_index)
		index = parent_index

# Ensure the heap property is maintained after removal
func _heapify_down(index: int):
	while true:
		var min_index = index
		var left_index = self._left_child(index)
		var right_index = self._right_child(index)
		var min_value = self._heap[index]
		
		if left_index < self._count:
			var left_child = self._heap[left_index]
			if self._less_than.call(left_child, min_value):
				min_index = left_index
				min_value = left_child

		if right_index < self._count:
			var right_child = self._heap[right_index]
			if self._less_than.call(right_child, min_value):
				min_index = right_index
				min_value = right_child
				
		if min_index == index:
			# all children are bigger than index
			break
			
		self._swap(index, min_index)
		index = min_index

func clear():
	for i in range(self._heap.size()):
		self._heap[i] = null
	self._count = 0

static func _unittest():
	var min_float = func(l: float, r: float) -> bool:
		return l < r
			
	var heap = MinHeap.new(min_float)
	
	var simple_test = func(h: MinHeap, vals: Array, do_insert: bool, check_refs: bool):
		if do_insert:
			h.clear()
			for v in vals:
				assert(h.push(v))
			vals.sort()
			
		var refs = []
		if check_refs:
			for v in vals:
				# -1 for the v
				refs.append(v.get_reference_count() - 1)
			
		var curr_count = vals.size()
		for v in vals:
			assert(v == h.pop_root())
			if check_refs:
				var ref_count = v.get_reference_count()
				# +1 for v, -1 after pop_root
				var expected = refs[refs.size() - curr_count] + 1 - 1
				assert(ref_count - 1 + 1 == expected,
					   "ref_count {0} != {1}".format([ref_count, expected]))
			curr_count -= 1
			assert(h.count == curr_count)
			
	for vals in [
		[0, 1, 2, 3, 4, 5, 6],
	 	[6, 5, 4, 3, 2, 1, 0],
		[2, 4, 6, 0, 3, 1, 5],
	]:
		simple_test.call(heap, vals, true, false)

	var bigger = []
	for v in range(100):
		bigger.append(v)
	simple_test.call(heap, bigger, true, false)
	assert(heap.cap == 128)

	heap.clear()
	for v in [7, 2, 5]:
		assert(heap.push(v))
	assert(2 == heap.pop_root())
	for v in [5, 4, 5, 6, 5]:
		assert(heap.push(v))
	assert(4 == heap.peek_root())
		
	var lt_obj = func(l, r) -> bool:
		return l.width < r.width
		
	heap = MinHeap.new(lt_obj)
	var tls = []
	for t in [6, 0, 5, 1, 3, 4, 2]:
		var tl = TextLine.new()
		tl.width = t
		tls.append(tl)
		assert(heap.push(tl))
		
	tls.sort_custom(lt_obj)
	simple_test.call(heap, tls, false, true)
