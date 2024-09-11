float halton_sequence(int base, inout ivec2 state) {
	int x = state.y - state.x;
	if (x == 1) {
		state.x = 1;
		state.y *= base;
	} else {
		int y = state.y / base;
		while (x <= y) {
			y /= base;
		}
		state.x = (base + 1) * y - x;
	}
	return float(state.x) / float(state.y);
}