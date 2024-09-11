float prng(inout int state) {
	state ^= state >> 7;
	state ^= (state << 9) & 0xffff;
	state ^= state >> 13;
	return float(state) / 65535.0;
}