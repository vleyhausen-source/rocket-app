#!/usr/bin/env python3
"""Generate coin PNG sprites (gold, blue, purple) with gradient and shine,
using only stdlib (struct, zlib). Each coin is 48x48px.
"""

import struct
import zlib
import math

SIZE = 48


def create_coin_pixels(base_r: int, base_g: int, base_b: int) -> bytes:
    """Generate RGBA pixel data for a coin with the given base color."""
    rows = []
    cx = SIZE / 2
    cy = SIZE / 2
    radius = SIZE / 2 - 2  # small padding

    for y in range(SIZE):
        row = bytearray()
        for x in range(SIZE):
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx * dx + dy * dy)

            if dist > radius:
                # Outside the coin: transparent
                row.extend([0, 0, 0, 0])
                continue

            r, g, b, a = 0, 0, 0, 255

            # Normalized distance from center (0=center, 1=edge)
            nd = dist / radius

            # Darker edge (rim effect)
            edge_dark = 0.7 + 0.3 * (1.0 - nd)
            # Radial gradient: center brighter
            center_bright = 1.0 - nd * 0.35

            # Base color with gradient
            br = int(base_r * edge_dark * center_bright)
            bg = int(base_g * edge_dark * center_bright)
            bb = int(base_b * edge_dark * center_bright)

            # Shine highlight (upper-left crescent)
            shine_dx = dx + 6
            shine_dy = dy + 6
            shine_dist = math.sqrt(shine_dx * shine_dx + shine_dy * shine_dy)
            shine_factor = max(0.0, 1.0 - shine_dist / (radius * 0.55))
            shine = shine_factor * 0.45

            # Rim highlight at top-left edge
            rim_dx = dx + 2
            rim_dy = dy + 2
            rim_angle = math.atan2(rim_dy, rim_dx)
            rim_factor = max(0.0, 1.0 - abs(rim_angle + math.pi / 4) / math.pi)
            rim_highlight = rim_factor * (1.0 - abs(nd - 0.85) * 10.0) * 0.3
            rim_highlight = max(0.0, rim_highlight)

            r = min(255, int(br + (255 - br) * shine + 200 * rim_highlight))
            g = min(255, int(bg + (255 - bg) * shine + 200 * rim_highlight))
            b = min(255, int(bb + (255 - bb) * shine + 200 * rim_highlight))

            a = 255
            row.extend([r, g, b, a])

        rows.append(bytes(row))
    return b''.join(rows)


def make_png(width: int, height: int, pixels: bytes) -> bytes:
    """Create a valid PNG file from raw RGBA pixel data."""
    signature = b'\x89PNG\r\n\x1a\n'

    # IHDR
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr = _chunk(b'IHDR', ihdr_data)

    # IDAT
    raw_rows = []
    for y in range(height):
        start = y * width * 4
        end = start + width * 4
        raw_rows.append(b'\x00' + pixels[start:end])
    compressed = zlib.compress(b''.join(raw_rows))
    idat = _chunk(b'IDAT', compressed)

    iend = _chunk(b'IEND', b'')
    return signature + ihdr + idat + iend


def _chunk(ctype: bytes, data: bytes) -> bytes:
    chunk = ctype + data
    crc = struct.pack('>I', zlib.crc32(chunk) & 0xFFFFFFFF)
    return struct.pack('>I', len(data)) + chunk + crc


def main():
    coins = [
        ('coin_gold.png', 220, 180, 40),     # golden
        ('coin_blue.png', 60, 130, 220),     # blue
        ('coin_purple.png', 170, 60, 210),   # purple
    ]

    for filename, r, g, b in coins:
        pixels = create_coin_pixels(r, g, b)
        png_data = make_png(SIZE, SIZE, pixels)
        path = f'/home/hermes-pi/projekte/rocket-app/assets/images/{filename}'
        with open(path, 'wb') as f:
            f.write(png_data)
        print(f'Created {path} ({len(png_data)} bytes, {SIZE}x{SIZE})')


if __name__ == '__main__':
    main()
