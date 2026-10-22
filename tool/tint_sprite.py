#!/usr/bin/env python3
"""Pre-tinta `button_square_depth_flat.png` con `AppTheme.seedColor` (#4361EE).

El tablero dibuja hasta 24 fichas por frame. En Impeller (sin raster cache de
capas), un `ColorFilter.mode(seedColor, BlendMode.modulate)` se vuelve a
evaluar en la GPU en cada frame para producir siempre el mismo resultado.
Multiplicar el sprite gris una sola vez offline elimina el filtro de color del
tablero sin cambiar ni un píxel del render.

Funciona sin dependencias externas sobre PNGs indexados (`PLTE`), que es el
formato de los sprites de Kenney (355 bytes), y usa Pillow como respaldo si se
le pasa un PNG RGBA directo.

Uso:
    python tool/tint_sprite.py
"""

from __future__ import annotations

import pathlib
import struct
import zlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "assets/ui/kenney/button_square_depth_flat.png"
DST = ROOT / "assets/ui/kenney/button_square_depth_flat_seed.png"

# AppTheme.seedColor = Color(0xFF4361EE)
TINT = (0x43, 0x61, 0xEE)


def _modulate(channel: int, tint: int) -> int:
    # Misma cuenta que `BlendMode.modulate`: canal * tinte // 255.
    return (channel * tint) // 255


def _tint_indexed_png(data: bytes, tint: tuple[int, int, int]) -> bytes | None:
    """Si `data` es un PNG de paleta (color_type == 3), multiplica su PLTE."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("No es un archivo PNG válido")

    out = bytearray(data[:8])
    pos = 8
    es_paleta = False
    plte_tintada = False

    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos : pos + 4])
        ctype = data[pos + 4 : pos + 8]
        chunk_data = data[pos + 8 : pos + 8 + length]
        pos += 12 + length

        if ctype == b"IHDR":
            color_type = chunk_data[9]
            es_paleta = color_type == 3
            if not es_paleta:
                return None

        if ctype == b"PLTE" and es_paleta:
            nuevo = bytearray(len(chunk_data))
            for i in range(0, len(chunk_data), 3):
                nuevo[i] = _modulate(chunk_data[i], tint[0])
                nuevo[i + 1] = _modulate(chunk_data[i + 1], tint[1])
                nuevo[i + 2] = _modulate(chunk_data[i + 2], tint[2])
            chunk_data = bytes(nuevo)
            plte_tintada = True

        crc = zlib.crc32(ctype + chunk_data) & 0xFFFFFFFF
        out.extend(struct.pack(">I", len(chunk_data)))
        out.extend(ctype)
        out.extend(chunk_data)
        out.extend(struct.pack(">I", crc))

    return bytes(out) if plte_tintada else None


def main() -> None:
    raw = SRC.read_bytes()
    tinted = _tint_indexed_png(raw, TINT)
    if tinted is not None:
        DST.write_bytes(tinted)
        print(f"Generado {DST.relative_to(ROOT)} ({len(tinted)} bytes, paleta tintada)")
        return

    # Respaldo con Pillow si el PNG de entrada no fuera indexado.
    from PIL import Image  # type: ignore[import-not-found]

    src = Image.open(SRC).convert("RGBA")
    px = [
        (
            _modulate(r, TINT[0]),
            _modulate(g, TINT[1]),
            _modulate(b, TINT[2]),
            a,
        )
        for r, g, b, a in src.getdata()
    ]
    out = Image.new("RGBA", src.size)
    out.putdata(px)
    out.save(DST)
    print(f"Generado {DST.relative_to(ROOT)} con Pillow")


if __name__ == "__main__":
    main()

