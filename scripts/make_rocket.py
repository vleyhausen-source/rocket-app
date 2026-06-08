#!/usr/bin/env python3
"""Generate a simple rocket PNG sprite using only stdlib (struct, zlib).

Creates an 80x160 pixel RGB PNG with a white/grey rocket with red nose,
pointing upward (vertical orientation), with subtle shading.
"""

import struct
import zlib
import sys

WIDTH = 80
HEIGHT = 160

def create_png_pixels() -> bytes:
    """Generate raw pixel data: RGBA rows, top-to-bottom."""
    rows = []
    # Rocket body geometry: centered horizontally at x=40 (range ~20-60)
    # Nose cone at top (y ~10-40), body down to y~140, fins at bottom
    for y in range(HEIGHT):
        row = bytearray()
        for x in range(WIDTH):
            dx = x - 40  # center offset
            r, g, b, a = 0, 0, 0, 0

            # Nose cone (red triangle): y 10 to 45
            if 10 <= y <= 45:
                half_w = max(0, 6.0 + (y - 10) * (20.0 / 35.0))
                # Tip: at y=10, half_w=6; at y=45, half_w=26
                if abs(dx) <= half_w:
                    # Gradient from bright red tip to darker red base
                    t = (y - 10) / 35.0
                    r = int(240 - t * 60)
                    g = int(50 - t * 30)
                    b = int(30 - t * 20)
                    # Highlight on left side
                    if dx < 0:
                        r = min(255, r + 30)
                        g = min(255, g + 20)
                    a = 255

            # Body (grey cylinder with white highlight): y 45 to 145
            elif 45 < y <= 145:
                if abs(dx) <= 20:  # body width = 40px
                    # Darker edge, lighter center
                    edge_factor = abs(dx) / 20.0  # 0 at center, 1 at edge
                    base_val = int(200 - edge_factor * 80)
                    r = g = b = base_val
                    # Lighter vertical stripe on left side
                    if -8 <= dx <= -2:
                        r = g = b = min(255, base_val + 30)
                    a = 255

            # Fins at bottom: y 145 to 160
            elif 145 < y <= 160:
                # Left fin
                if -30 <= dx <= -20:
                    fy = (y - 155) / 5.0  # -1 at y=150, +1 at y=155
                    if abs(fy) <= 1.0:
                        r = 180
                        g = 60
                        b = 40
                        a = 255
                # Right fin
                if 20 <= dx <= 30:
                    fy = (y - 155) / 5.0
                    if abs(fy) <= 1.0:
                        r = 180
                        g = 60
                        b = 40
                        a = 255
                # Center fin (front-facing)
                if -5 <= dx <= 5 and y >= 146:
                    r = 170
                    g = 160
                    b = 150
                    a = 255

            # Body line continuation at bottom
            elif 45 <= y <= 145:
                if abs(dx) <= 20:
                    edge_factor = abs(dx) / 20.0
                    base_val = int(200 - edge_factor * 80)
                    r = g = b = base_val
                    a = 255

            row.extend([r, g, b, a])
        rows.append(bytes(row))
    return b''.join(rows)


def make_png(width: int, height: int, pixels: bytes) -> bytes:
    """Create a valid PNG file from raw RGBA pixel data."""
    # PNG signature
    signature = b'\x89PNG\r\n\x1a\n'

    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    # 8=bit depth, 6=RGBA, 0=deflate, 0=adaptive filter, 0=no interlace
    ihdr = _chunk(b'IHDR', ihdr_data)

    # IDAT chunk: filter bytes + pixel data
    raw_rows = []
    for y in range(height):
        # Filter byte 0 (None filter) + row data
        start = y * width * 4
        end = start + width * 4
        raw_rows.append(b'\x00' + pixels[start:end])
    raw_data = b''.join(raw_rows)
    compressed = zlib.compress(raw_data)
    idat = _chunk(b'IDAT', compressed)

    # IEND chunk
    iend = _chunk(b'IEND', b'')

    return signature + ihdr + idat + iend


def _chunk(chunk_type: bytes, data: bytes) -> bytes:
    """Build a PNG chunk."""
    chunk = chunk_type + data
    crc = struct.pack('>I', zlib.crc32(chunk) & 0xFFFFFFFF)
    return struct.pack('>I', len(data)) + chunk + crc


def main():
    pixels = create_png_pixels()
    png_data = make_png(WIDTH, HEIGHT, pixels)
    output_path = '/home/hermes-pi/projekte/rocket-app/assets/images/rocket.png'
    with open(output_path, 'wb') as f:
        f.write(png_data)
    print(f'Created {output_path} ({len(png_data)} bytes, {WIDTH}x{HEIGHT})')


if __name__ == '__main__':
    main()
