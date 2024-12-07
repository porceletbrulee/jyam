class_name GameState extends RefCounted

var _dance3d_ref: Dance3D
var _song_timer_ref: SongTimer = null
var _platforms_ref: GamePlatforms = null
var _player_to_dancer: Dictionary
var _inputmatcher_ref: GameInputMatcher = null

var _player_to_anticipation_meter: Dictionary

var _paused: bool = false

var _last_beat: int
var _last_measure: int

func _init(dance3d: Dance3D,
		   song_timer: SongTimer,
		   inputmatcher_ui: InputMatcherUI,
		   platforms: GamePlatforms,
		   dancers: Array):
	self._dance3d_ref = dance3d
	self._song_timer_ref = song_timer
	self._platforms_ref = platforms
	self._player_to_dancer = {}
	for d in dancers:
		self._player_to_dancer[d.player] = d
		self._player_to_anticipation_meter[d.player] = 0
		self._platforms_ref.set_dancer(d, d.platform_pos)

	self._inputmatcher_ref = GameInputMatcher.new(inputmatcher_ui,
												 song_timer.beats_per_measure * 2)

	self._paused = false

	self._last_beat = -1
	self._last_measure = -1

func anticipation_meter(player: GameLogic.Player) -> int:
	var val = self._player_to_anticipation_meter.get(player)
	assert(val != null)
	return val

func _enter_closed_position(lead: GameDancer, follow: GameDancer, move_dir: Vector2):
	print_debug("enter: lead {0} follow {1} {2}".format([lead, follow, move_dir]))

	# TODO: breaking some abstractions here, figure out something better
	var lead_rtl = lead.dancer3d.get_facecam_text_label()
	var follow_rtl = follow.dancer3d.get_facecam_text_label()

	var _eventify = func(funcs) -> Callable:
		var _f = func(_context):
			for f in funcs:
				f.call()
		return _f

	var _move_dancers = func():
		var plat = self._platforms_ref.get_platform(lead.platform_pos)
		assert(plat != null)

		var move_duration_sec = self._song_timer_ref.sec_per_beat
		lead.trigger_move_to_closed_position(plat, GameLogic.opposite_dir(move_dir), move_duration_sec)
		follow.trigger_move_to_closed_position(plat, move_dir, move_duration_sec)

		var finish_move = func(_context2):
			self._platforms_ref.finish_move(lead, plat)
			self._platforms_ref.finish_move(follow, plat)
			lead.finish_move_to_closed_position(self._song_timer_ref)
			follow.finish_move_to_closed_position(self._song_timer_ref)

		self._song_timer_ref.insert_delayed_event(move_duration_sec, finish_move)

	var interval = self._song_timer_ref.sec_per_beat
	var events = [
		[interval * 0, _eventify.call(
				[
					func(): lead.dancer3d.show_facecam(),
					func(): lead_rtl.append_text("please please please"),
				],
			)
		],
		[interval * 1, func(_context): lead_rtl.append_text("\nplease please please")],
		[interval * 2, func(_context): lead_rtl.append_text(" [b]please![/b]")],
		[interval * 3, _eventify.call([
			func(): follow.dancer3d.show_facecam(),
			func(): follow_rtl.append_text("..."),
		])],
		[interval * 4, func(_context): follow_rtl.append_text("ok")],
		[interval * 6, _eventify.call([
			func(): lead.dancer3d.hide_facecam(),
			func(): follow.dancer3d.hide_facecam(),
			_move_dancers,
		])],
		[interval * 7, _eventify.call([
			func(): self._inputmatcher_ref.begin_inputmatcher(lead.player),
			# TODO: expiration for input matching
		])]
	]
	for i in events:
		self._song_timer_ref.insert_delayed_event(i[0], i[1])

func _move_player(player: GameLogic.Player, move_dir: Vector2):
	var dancer = self._player_to_dancer[player]
	assert(dancer != null)

	if not dancer.can_move():
		# TODO: allow some input buffering
		return false

	var dst_plat = self._platforms_ref.attempt_begin_move(dancer, move_dir)
	if dst_plat == null:
		return false

	if dst_plat.dancers.size() > 0:
		# there should only be one other dancer
		var partner: GameDancer = dst_plat.dancers.values()[0]

		if partner.is_inviting():
			if not partner.invite_accepted(self._song_timer_ref, dancer):
				return false

			self._enter_closed_position(partner, dancer, move_dir)
			return true
		else:
			return false

	var src_plat = self._platforms_ref.get_platform(dancer.platform_pos)
	assert(src_plat != null)

	# a move takes 1 beat
	var move_duration_sec = self._song_timer_ref.sec_per_beat
	dancer.trigger_move(src_plat, dst_plat, move_duration_sec)

	# closures might be inefficient and/or hard to debug
	var finish_move = func(_context):
		self._platforms_ref.finish_move(dancer, dst_plat)
		dancer.finish_move(self._song_timer_ref)

	self._song_timer_ref.insert_delayed_event(move_duration_sec, finish_move)

	return true

func _invite_player(player: GameLogic.Player) -> bool:
	var dancer = self._player_to_dancer[player]
	assert(dancer != null)

	if not dancer.can_invite():
		return false

	var invite_expired = dancer.trigger_invite(self._song_timer_ref)
	if invite_expired.is_null():
		return false

	self._dance3d_ref.spotlight_platform(dancer.platform_pos)
	self._dance3d_ref.dim_ambient()

	var expired = func(context):
		if invite_expired.call(context):
			self._dance3d_ref.unspotlight()
			self._dance3d_ref.reset_ambient()

	self._song_timer_ref.insert_delayed_event(
		self._song_timer_ref.sec_per_measure * 3, expired
	)

	return true

func _process_inputmatcher_dequeued(
	lead_action: GameInputs.Action,
	follower_action: GameInputs.Action):
	print_debug("dequeued {0} {1}".format([lead_action, follower_action]))

func _inputmatcher_enqueue(player: GameLogic.Player, action: GameInputs.Action) -> bool:
	# TODO: some UX to hint mis-input
	if not self._inputmatcher_ref.enqueue_input(player, action):
		return false

	if (self._inputmatcher_ref.is_lead_full() and
		self._inputmatcher_ref.is_follower_full()):
		var end = func (_context):
			self._inputmatcher_ref.end_inputmatcher()

			var lead = self._inputmatcher_ref.lead_player
			var follower = GameLogic.opposite_player(lead)
			var inputs = self._inputmatcher_ref.dequeue_all()
			var delay = 0
			for player_inputs in inputs:
				var f = func(_context):
					var lead_input = player_inputs[lead]
					var follower_input = player_inputs[follower]
					self._process_inputmatcher_dequeued(
						lead_input, follower_input
					)

				self._song_timer_ref.insert_delayed_event(delay, f)
				delay += self._song_timer_ref.sec_per_measure
			# TODO: enqueue something to transition to next state

		self._song_timer_ref.insert_delayed_event(
			self._song_timer_ref.sec_per_measure,
			end,
		)

	return true

func _perform_action(action: GameInputs.Action) -> bool:
	if self._inputmatcher_ref.is_dequeueing_inputs:
		return false

	var player = GameInputs.ACTION_TO_PLAYER.get(action)

	if self._inputmatcher_ref.is_accepting_inputs:
		return self._inputmatcher_enqueue(player, action)

	var move_dir = GamePlatforms.ACTION_TO_MOVE_DIR.get(action)
	if move_dir != null:
		return self._move_player(player, move_dir)

	if (action == GameInputs.Action.P1_INVITE or
		action == GameInputs.Action.P2_INVITE):
		return self._invite_player(player)

	return false

func input(event: InputEvent) -> void:
	# TODO: does _input race with _physics_process??
	for action_str in GameInputs.Action:
		if event.is_action_pressed(action_str):
			var action = GameInputs.Action[action_str]
			self._perform_action(action)

func _on_measure():
	for p in self._player_to_anticipation_meter:
		var old_meter = self._player_to_anticipation_meter[p]
		var meter = old_meter + GameLogic.ANTICIPATION_GROWTH_PER_MEASURE
		meter = mini(meter, GameLogic.ANTICIPATION_METER_MAX)
		if old_meter != meter:
			self._player_to_anticipation_meter[p] = meter
			self._dance3d_ref.update_player_meter(p, meter)

	for dancer in self._player_to_dancer.values():
		# run the idle animation every measure
		dancer.on_measure(self._song_timer_ref)

func _on_beat():
	for dancer in self._player_to_dancer.values():
		# run the idle animation every measure
		dancer.on_beat(self._song_timer_ref)

func play_song():
	self._song_timer_ref.play()

func physics_process(delta: float) -> void:
	# update SongTimer first so time is up-to-date
	self._song_timer_ref.physics_process(delta)

	var beat = self._song_timer_ref.beat
	if self._last_beat != beat:
		if self._last_beat + 1 != beat:
			print_debug("jumped {0} beats, dropping frames?".format([
				beat - self._last_beat
			]))
		self._on_beat()
		self._last_beat = beat

	var measure = self._song_timer_ref.measure
	if measure != self._last_measure:
		if self._last_measure + 1 != measure:
			print_debug("jumped {0} measures, dropping frames?".format([
				measure - self._last_measure
			]))
		self._on_measure()
		self._last_measure = measure
