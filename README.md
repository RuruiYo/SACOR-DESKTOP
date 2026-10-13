# SACOR Desktop

Aplicación de escritorio para Windows del **administrador de SACOR** (retiro de desechos de centros
comerciales). Lleva la planilla de empleados, el cuadro de pesaje y el movimiento contable, y permite
agregar, editar y eliminar los datos de la empresa.

Construida con **Flutter + Dart**, **Provider** (estado) y **fl_chart** (gráficos).

**Usa únicamente lo que ya existe en la API y la base de datos de SACOR** (rama `main` del repositorio
de la API): el CRUD de cada tabla (`/api/empleados`, `/api/pesajes`, …) con la llave `AppEscritorio` en
el header `X-Api-Key`, y `/api/auditoria`. Requiere la columna `ruta_trabajo.id_cotizacion` y el endpoint de generación de viajes (script `db/agregar_tablas_movil.sql` de la API).

## Módulos

| Módulo | Qué hace |
|---|---|
| Acceso | Entra un empleado tipo `Administrador` y estado `Activo` escribiendo su `codigo_empleado` (el mismo de la app móvil). 5 intentos fallidos bloquean un minuto; la sesión se cierra tras 30 minutos sin uso. |
| Empleados | Planilla con alta, edición y baja. Al crear un empleado se genera su código (6 dígitos administradores, 4 los demás, como la app móvil). Por empleado: pagos y anticipos (alta, edición, baja) y "Ver código". |
| Pesaje | Cuadro mensual por plaza como el Excel "CUADRO DE PESAJE": una fila por día y, por cada tipo de desecho, libras (por etapa si se usan), toneladas (libras ÷ 2200), precio por tonelada y total. Tocar un día abre sus pesajes para agregar, corregir o borrar. Resumen de todas las plazas, IVA 13 %, pago a cuenta 1.75 %. |
| Movimiento contable | Ventas, gastos, ganancia y margen del período con su variación contra el período anterior; ventas y gastos de los últimos 12 meses; ventas por plaza; gastos por categoría; IVA y pago a cuenta. |
| Clientes y contratos | Clientes (Plaza Mundo, Metrocentro, personas naturales…), contratos por plaza y tipo de desecho (`servicio_contrato`) y precios por tonelada (`precio_lugar`). |
| Servicios externos | Lo que SACOR contrata: góndola, relleno sanitario, mantenimiento… |
| Salidas y camiones | Cada salida (`ruta_trabajo`) es un día de trabajo en un lugar: quiénes van y cuánto llevan para gasolina. Camiones. |
| Viajes extra | Viajes fuera del contrato, con su personal. |
| Solicitudes web | Cotizaciones y postulaciones que la gente envía desde el sitio web (las guarda la web en `cotizacion` y `solicitud_puesto_trabajo`). Cotizaciones: cambiar estado (Pendiente, En revisión, Cotizada, Aprobada, Rechazada, Cerrada), quien la cambia queda como analista. Postulaciones: marcar como atendida (queda el administrador como analista). Ambas: eliminar y "Escribir por WhatsApp" con un saludo ya escrito. Experiencia, municipio, licencia y mensaje de una postulación llegan solo por WhatsApp: la web no los guarda. |
| Viajes de cotizaciones | En una cotización **Aprobada**, "Generar viajes" crea las salidas (una por viaje, con fecha según la frecuencia), el cliente, el precio y el contrato llamando a `POST /api/cotizaciones/{id}/generar-viajes`. En Salidas y camiones, el filtro "Cotización web" muestra esos viajes y "Asignar a todos los viajes" pone el mismo personal en todos. |
| DTE | Lee los JSON de DTE (formato de Hacienda) que se guardan en `Documentos\SACOR\DTE`: tipo, número de control, emisor, receptor, gravado, IVA, total; IVA crédito y débito. **No envía nada a la API** (la base no tiene tabla de DTE). |
| Auditoría | Historial de `auditoria`. La app registra ahí cada alta, edición y baja (sin copiar el código del empleado). |

Planilla, cuadro de pesaje, servicios externos y movimiento contable se exportan a **Excel, PDF y CSV**.

## Cómo se calculan las cifras

- **Ventas** = pesajes (peso en libras ÷ 2200 × precio por tonelada del `precio_lugar` del pesaje) +
  viajes extra (precio × cantidad).
- **Gastos** = pagos (cantidad − descuento) + anticipos (en su fecha) + servicios externos + gasolina de
  cada salida (`dinero_gasolina`).
- **Ganancia** = ventas − gastos. **IVA** = 13 % de las ventas. **Pago a cuenta** = 1.75 % de las ventas.
- **Variación** = ((actual − anterior) / anterior) × 100, contra un período anterior de la misma duración.

Con los pesajes de agosto 2026 del Excel, la app da los mismos totales: Apopa $1,866.36, Soyapango
$3,562.56 y Usulután $2,318.35 (precio nuevo). Está comprobado en las pruebas automáticas.

### Fecha dentro del texto

`servicio_externo`, `viaje_extra` y `ruta_trabajo` no tienen columna de fecha. La app guarda la fecha
al inicio del texto y la lee de ahí:

| Tabla | Columna | Ejemplo |
|---|---|---|
| servicio_externo | nombre | `[2026-08] Góndola 1-15 agosto` |
| viaje_extra | tipo | `[2026-08] Transporte extra andamios` |
| ruta_trabajo | destino | `[2026-08-14] Plaza Mundo Apopa` |

Los registros sin ese formato (por ejemplo, los que crea la app móvil) cuentan en los totales pero no
en ningún mes; la app los señala para que se les ponga fecha.

## Probarlo en una laptop

Requisitos: Flutter 3.47+, .NET 8 SDK, SQL Server Express **LocalDB** y `sqlcmd`, y la carpeta de la
API (`API_SACOR`). No hace falta SSMS ni la base de Steven.

```powershell
# 1. Base de prueba en LocalDB: tablas de db/sacor_db.sql (sin cambios) + datos de prueba
.\herramientas\base_local.ps1

# 2. La API original contra esa base (deje esta ventana abierta)
.\herramientas\api_local.ps1

# 3. En otra ventana, la app
flutter run -d windows
```

Código del administrador de prueba: **482913**. `api_local.ps1` configura la API solo con variables de
entorno de ese proceso (cadena de conexión, una llave de prueba para `AppEscritorio` y el origen de la
vista previa web) y escribe `sacor_config.json` para la app. Si la API está en otra carpeta:
`-RutaApi "D:\repos\API_SACOR"`.

Sin Visual Studio C++ se puede ver en el navegador (desarrollo):

```powershell
$llave = (Get-Content herramientas\llave_local.txt -Raw).Trim()
flutter run -d edge --web-port 7357 --dart-define=SACOR_API_KEY=$llave
```

Modo demostración (datos ficticios en memoria, sin API): `flutter run -d windows --dart-define=SACOR_DEMO=true`.

## Correrlo en la computadora de Steven (con su base y su API)

Requisitos: Flutter 3.47+ y Visual Studio con **"Desarrollo para el escritorio con C++"** (la API y SQL
Server ya los tiene).

1. Clonar y bajar dependencias:
   ```powershell
   git clone https://github.com/diegoelias90/sacor-desktop.git
   cd sacor-desktop
   flutter pub get
   ```
2. Darle valor a la llave `AppEscritorio` de la API (ya existe vacía en `appsettings.json`). Generar
   una llave y dejarla en una variable de entorno antes de levantar la API:
   ```powershell
   $b = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
   $llave = ($b | ForEach-Object { $_.ToString('x2') }) -join ''
   $env:Seguridad__ApiKeys__AppEscritorio = $llave
   dotnet run --project APISacor --urls http://localhost:5084
   ```
   En un servidor, la misma llave va como variable de entorno del servicio o en su configuración.
3. En la carpeta de la app, crear `sacor_config.json` con la dirección de la API y la misma llave:
   ```json
   { "apiUrl": "http://localhost:5084", "apiKey": "<la llave>" }
   ```
4. Correr la app y entrar con el `codigo_empleado` de un administrador activo:
   ```powershell
   flutter run -d windows
   ```

Ojo: así la app trabaja sobre la base real (todo cambio queda en `auditoria`). Para probar sin tocarla,
usar los pasos de la sección anterior (`base_local.ps1` y `api_local.ps1` con
`-RutaApi "<carpeta de la API>"`), que crean una base aparte en LocalDB.

Para entregar la app en otras PC: `.\herramientas\compilar_windows.ps1 -ApiUrl "<dirección de la API>"
-ApiKey "<la llave>"` deja `build\SACOR.Desktop.zip`.

## Configuración

`sacor_config.json` junto a `SACOR.Desktop.exe` (con `flutter run`, en la carpeta del proyecto):

```json
{
  "apiUrl": "https://api-sacor.ejemplo.com",
  "apiKey": "valor de Seguridad:ApiKeys:AppEscritorio",
  "nitEmpresa": "0614-000000-000-0",
  "carpetaDte": "D:\\SACOR\\DTE",
  "modoDemo": false
}
```

`nitEmpresa` separa los DTE emitidos (ventas) de los recibidos.

Carpeta de DTE: en cada computadora se usa, en este orden, (1) la que el usuario eligió en la pantalla
DTE con **"Cambiar carpeta…"** (queda guardada para ese usuario de Windows en
`%APPDATA%\SACOR\preferencias.json`), (2) `carpetaDte` de `sacor_config.json`, o (3) la carpeta
Documentos de ese usuario + `SACOR\DTE`, que la app crea si no existe.

`sacor_config.json` lleva la llave de la API: no lo suba a git (ya está en `.gitignore`) ni lo comparta
fuera de SACOR.

## Compilar el ejecutable de Windows

Requiere **Visual Studio** con la carga de trabajo **"Desarrollo para el escritorio con C++"**.

```powershell
.\herramientas\compilar_windows.ps1 -ApiUrl "https://api-sacor.ejemplo.com" -ApiKey "<llave AppEscritorio>"
```

Corre las pruebas, compila en modo release, copia el runtime de Visual C++ y deja
`build\SACOR.Desktop.zip` listo para descomprimir en otra PC.

## Pruebas

```powershell
flutter test                                                    # 77 pruebas (lógica, datos e interfaz)
flutter test --tags api --run-skipped test/integracion         # contra la API local (base de prueba)
flutter test --tags capturas --run-skipped --update-goldens test/capturas   # capturas de diseño
```

La prueba de integración crea, edita y borra registros de cada tabla: córrala solo contra la base
local de `base_local.ps1`.

## Límites conocidos

- La API acepta **120 peticiones por minuto por llave**. Al entrar, la app lee todas las tablas (unas 20
  peticiones) y cada cambio usa 2 (el cambio y su auditoría). Si se pasa del límite, la app avisa y las
  auditorías pendientes se reenvían solas en la siguiente operación.
- `GET /api/empleados` devuelve `codigo_empleado`: así valida la app el acceso, porque la API no tiene
  login para escritorio. Cualquiera con la llave `AppEscritorio` puede leer esos códigos.
- La API no filtra por fecha: la app trae todas las filas y calcula en memoria. Con muchos años de datos
  la carga inicial tarda más.

## Estructura

```
lib/
  calculos/       contabilidad (ventas, gastos, ganancia) y planilla de pesaje
  configuracion/  sacor_config.json y valores de compilación
  datos/          cliente HTTP, recursos de la API, modelos y datos de demostración
  dte/            lectura de los JSON de DTE
  estado/         almacén de datos, sesión, período y navegación (Provider)
  exportacion/    CSV, Excel y PDF
  nucleo/         dinero, formatos, períodos, fecha dentro del texto, tema
  ui/             pantallas
herramientas/     base_local.ps1, api_local.ps1, datos_prueba.sql, compilar_windows.ps1
test/             pruebas
```
