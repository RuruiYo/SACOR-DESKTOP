import pathlib
import struct

RAIZ = pathlib.Path(__file__).resolve().parent.parent
TAMANOS = [16, 24, 32, 48, 64, 256]

def main() -> None:
    imagenes = [(t, (RAIZ / "test" / "capturas" / "icono" / f"icono_{t}.png").read_bytes()) for t in TAMANOS]

    encabezado = struct.pack("<HHH", 0, 1, len(imagenes))
    desplazamiento = 6 + 16 * len(imagenes)
    directorio = b""
    datos = b""
    for tamano, png in imagenes:
        lado = 0 if tamano >= 256 else tamano
        directorio += struct.pack("<BBBBHHII", lado, lado, 0, 0, 1, 32, len(png), desplazamiento + len(datos))
        datos += png

    destino = RAIZ / "windows" / "runner" / "resources" / "app_icon.ico"
    destino.write_bytes(encabezado + directorio + datos)
    print(f"Icono escrito en {destino} ({len(imagenes)} tamaños)")

if __name__ == "__main__":
    main()
