# DevSecretsManagerPs

`DevSecretsManagerPs` es un script de PowerShell para gestionar secretos de desarrollo por proyecto sin guardar los valores secretos en el repositorio.

El script usa un archivo local `env.json` junto a `SecretsManager.ps1` para identificar el proyecto, y guarda los secretos reales en el directorio home del usuario:

```text
<HOME>/.devsecretsmanager/<guid>.json
```

## Script

```powershell
.\SecretsManager.ps1
```

Version actual:

```powershell
.\SecretsManager.ps1 -Version
```

Retorna:

```text
2.0.0
```

`-Version` y `-Help` no inicializan ni crean archivos.

Los comandos que retornan salida por pipeline retornan JSON. `-Edit` solo muestra informacion en pantalla y no retorna un valor por pipeline. Los mensajes informativos, warnings con color, confirmaciones y avisos de busqueda se escriben con `Write-Host` y no estan pensados para capturarse como salida del comando.

## Instalar En Un Proyecto Consumidor Con ToolsManagerPs

Los proyectos consumidores pueden instalar este repositorio como herramienta usando `ToolsManagerPs`.

Descargar `ProjectManager.ps1` en la raiz del proyecto consumidor:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Satancito/ToolsManagerPs/main/ProjectManager.ps1" -OutFile "ProjectManager.ps1" -UseBasicParsing
```

Inicializar la configuracion del proyecto consumidor:

```powershell
.\ProjectManager.ps1 -Init
```

Agregar `DevSecretsManagerPs` como herramienta Git submodule:

```powershell
.\ProjectManager.ps1 -Tools Add -RepositoryName DevSecretsManagerPs -RepositoryUrl https://github.com/Satancito/DevSecretsManagerPs.git -Tag ""
```

`-Tag ""` guarda `Tag` como `null`. Un tag `null` significa que la herramienta se actualiza al ultimo commit remoto cuando se ejecuta `-Tools Update`.

El valor de `-Tag` puede ser:

- `null`, pasando `-Tag ""`, para seguir el ultimo commit remoto.
- Un tag de Git, para fijar la herramienta a una version publicada.
- Un SHA de commit de Git, para fijar la herramienta a un commit exacto.

## Archivos

### Documentacion Del Repositorio

Los siguientes archivos de documentacion son parte de este repositorio:

- `README.md`: documentacion principal de uso, instalacion, comandos y comportamiento en ingles.
- `README.es-ES.MD`: documentacion principal de uso, instalacion, comandos y comportamiento en espanol.
- `CHANGELOG.md`: historial de releases y cambios pendientes.
- `Version.MD`: flujo de release local del repositorio en ingles.
- `Version.es-ES.MD`: flujo de release local del repositorio en espanol.

`README.md` y `README.es-ES.MD` deben mantenerse alineados cuando cambia el uso, instalacion, comandos o comportamiento.

`Version.MD` y `Version.es-ES.MD` son documentos de flujo de release para este repositorio. No son archivos de setup para proyectos consumidores.

### env.json

Ubicacion:

```text
<script-directory>/env.json
```

Formato:

```json
{
  "Id": "<guid>"
}
```

Este archivo identifica el conjunto de secretos usado por el proyecto. Si no existe, `-Init` lo crea. Si existe pero esta vacio, es invalido, no es un objeto JSON, o contiene un `Id` invalido, `-Init` lo regenera. Si existe pero no contiene `Id`, el script agrega esa propiedad preservando cualquier otra propiedad.

### Archivo De Secretos

Ubicacion:

```text
<HOME>/.devsecretsmanager/<guid>.json
```

Formato:

```json
{
  "ApiKey": "secret value",
  "OptionalSecret": null,
  "EmptySecret": ""
}
```

Los secretos se guardan como valores JSON directos. El script no guarda propiedades extra como `Value`, `Type` o `Sensitive`.

## Validacion

Todos los comandos operativos, excepto `-Regenerate`, inicializan y validan el entorno antes de ejecutarse:

- Crea `env.json` si no existe.
- Crea `<HOME>/.devsecretsmanager` si no existe.
- Crea `<guid>.json` si no existe.
- Regenera `env.json` cuando esta vacio, es invalido, no es un objeto JSON, o contiene un `Id` invalido.
- Regenera `<guid>.json` cuando el archivo de secretos esta vacio.
- Se detiene con error cuando el archivo de secretos tiene sintaxis JSON invalida.
- Se detiene con error cuando el archivo de secretos no contiene un objeto JSON.

`-Regenerate` es la excepcion: primero elimina `env.json`, luego inicializa un entorno nuevo.

## Help

```powershell
.\SecretsManager.ps1 -Help
.\SecretsManager.ps1 -h
```

Retorna la ayuda resumida del script como JSON. No crea ni modifica archivos.

## Init

```powershell
.\SecretsManager.ps1 -Init
```

Inicializa el entorno actual.

Hace lo siguiente:

- Crea `env.json` si no existe.
- Regenera `env.json` si esta vacio, es invalido, no es un objeto JSON, o contiene un `Id` invalido.
- Agrega `Id` a `env.json` si falta.
- Crea `<HOME>/.devsecretsmanager` si no existe.
- Crea `<guid>.json` si no existe.
- Valida que los archivos JSON existentes contengan objetos validos.

Muestra informacion de estado no capturable:

```text
Environment Id: ...
env.json: ... [Created|Existing|Regenerated|IdAdded]
Secrets directory: ... [Created|Existing]
Secrets file: ... [Created|Existing|Regenerated]
```

Al final, retorna el path completo del archivo de secretos `guid.json` como string JSON:

```powershell
$path = .\SecretsManager.ps1 -Init | ConvertFrom-Json
```

## Add

```powershell
.\SecretsManager.ps1 -Add <SecretName>
.\SecretsManager.ps1 -Add <SecretName> -Value <Value>
.\SecretsManager.ps1 -Add <SecretName> -Empty
.\SecretsManager.ps1 -Add <SecretName> -Value <Value> -Force
```

Agrega un secreto.

Comportamiento:

- Sin `-Value` ni `-Empty`, guarda `null`.
- Con `-Value "abc"`, guarda `"abc"`.
- Con `-Value ""`, guarda un string vacio.
- Con `-Empty`, guarda un string vacio.
- Si el secreto ya existe, no se reemplaza salvo que se use `-Force`.
- Con `-Force`, reemplaza secretos existentes y agrega secretos faltantes.

Valor de retorno JSON:

- `true` cuando el secreto fue agregado o reemplazado.
- `false` cuando el secreto ya existia y no se uso `-Force`.

Ejemplos:

```powershell
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "abc123" | ConvertFrom-Json
$saved = .\SecretsManager.ps1 -Add OptionalSecret | ConvertFrom-Json
$saved = .\SecretsManager.ps1 -Add EmptySecret -Empty | ConvertFrom-Json
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "new-value" -Force | ConvertFrom-Json
```

Resultado JSON:

```json
true
```

## Get

```powershell
.\SecretsManager.ps1 -Get <SecretName>
```

Obtiene el valor de un secreto.

Comportamiento:

- Si el secreto existe, muestra que fue encontrado.
- Si el valor es `null`, muestra `Value: null` en cyan.
- Si el valor es un string vacio, muestra `Value: empty` en cyan.
- Si el secreto no existe, muestra que no existe y retorna `null`.
- No falla cuando el secreto no existe.

Valor de retorno JSON:

- El valor del secreto como JSON cuando el secreto existe.
- `null` cuando el secreto no existe.
- `null` cuando el secreto existe y su valor guardado es `null`.
- `""` cuando el secreto existe y su valor guardado es un string vacio.

Ejemplo:

```powershell
$apiKey = .\SecretsManager.ps1 -Get ApiKey | ConvertFrom-Json
```

## Exists

```powershell
.\SecretsManager.ps1 -Exists <SecretName>
```

Verifica si un secreto existe sin mostrar su valor.

Valor de retorno JSON:

- `true` cuando el secreto existe.
- `false` cuando el secreto no existe.

Retorna `true` incluso cuando el valor del secreto es `null` o un string vacio.

Ejemplo:

```powershell
$exists = .\SecretsManager.ps1 -Exists ApiKey | ConvertFrom-Json
if (-not $exists) {
    throw "ApiKey is not configured"
}
```

## List

```powershell
.\SecretsManager.ps1 -List
```

Retorna el contenido JSON crudo del archivo de secretos actual.

Ejemplo:

```powershell
$json = .\SecretsManager.ps1 -List
```

Salida:

```json
{
  "ApiKey": "abc123",
  "OptionalSecret": null,
  "EmptySecret": ""
}
```

## Edit

```powershell
.\SecretsManager.ps1 -Edit
.\SecretsManager.ps1 -Edit -Editor <EditorName>
```

Abre el archivo de secretos actual en un editor.

Este comando solo muestra informacion en pantalla y no retorna un valor por pipeline.

Editor por defecto:

- Windows: `Notepad`
- Linux/macOS/Unix-like: `vi`

Ejemplos:

```powershell
.\SecretsManager.ps1 -Edit
.\SecretsManager.ps1 -Edit -Editor code
```

## Remove

```powershell
.\SecretsManager.ps1 -Remove <SecretName>
.\SecretsManager.ps1 -Remove <SecretName> -Force
```

Elimina un secreto.

Comportamiento:

- Siempre muestra primero el valor usando la misma logica visual de `-Get`.
- Si el secreto existe, tambien muestra una tabla con el valor que se eliminara.
- Sin `-Force`, pide confirmacion.
- Elimina solo cuando se confirma con `y` o `yes`.
- La confirmacion no distingue mayusculas/minusculas: `Y`, `YES`, `yEs`, etc. son validos.
- Los prompts de confirmacion se muestran en amarillo claro.
- Cuando la confirmacion es aceptada, muestra `Confirmed.` en verde claro.
- Con `-Force`, no pregunta y elimina directamente.
- No falla cuando el secreto no existe.

Valor de retorno JSON:

- `true` cuando el secreto fue eliminado.
- `false` cuando el secreto no existia o la eliminacion no fue confirmada.

Ejemplos:

```powershell
$removed = .\SecretsManager.ps1 -Remove ApiKey | ConvertFrom-Json
$removed = .\SecretsManager.ps1 -Remove ApiKey -Force | ConvertFrom-Json
```

## Clear

```powershell
.\SecretsManager.ps1 -Clear
.\SecretsManager.ps1 -Clear -Force
```

Elimina todos los secretos del archivo de secretos actual, dejando el JSON como:

```json
{}
```

Comportamiento:

- Sin `-Force`, pide confirmacion.
- Con `-Force`, limpia sin preguntar.
- Los prompts de confirmacion se muestran en amarillo claro.
- Cuando la confirmacion es aceptada, muestra `Confirmed.` en verde claro.

Valor de retorno JSON:

- `true` cuando el archivo fue limpiado.
- `false` cuando la accion fue cancelada.

## Regenerate

```powershell
.\SecretsManager.ps1 -Regenerate
.\SecretsManager.ps1 -Regenerate -Force
```

Regenera el entorno del proyecto.

Hace lo siguiente:

- Elimina `env.json`.
- Crea un nuevo `env.json` con un nuevo `Id`.
- Inicializa un nuevo archivo `<HOME>/.devsecretsmanager/<new-guid>.json`.

Comportamiento:

- Sin `-Force`, pide confirmacion.
- Con `-Force`, regenera sin preguntar.
- Si se cancela, no elimina `env.json`.

Valor de retorno JSON:

- `true` cuando el entorno fue regenerado.
- `false` cuando la accion fue cancelada.

## Version

```powershell
.\SecretsManager.ps1 -Version
```

Retorna la version del script como JSON.

```json
"2.0.0"
```

No inicializa ni modifica archivos.

## Salida JSON

El script separa los mensajes visibles de la salida JSON por pipeline. `-Edit` abre el editor y no retorna un valor por pipeline.

Ejemplos:

```powershell
$init = .\SecretsManager.ps1 -Init | ConvertFrom-Json
$saved = .\SecretsManager.ps1 -Add ApiKey -Value "abc123" | ConvertFrom-Json
$value = .\SecretsManager.ps1 -Get ApiKey | ConvertFrom-Json
$exists = .\SecretsManager.ps1 -Exists ApiKey | ConvertFrom-Json
$removed = .\SecretsManager.ps1 -Remove ApiKey -Force | ConvertFrom-Json
```

Los mensajes informativos se muestran en pantalla con `Write-Host`; la salida escrita al pipeline es JSON.

## Flujo Recomendado

Inicializar una vez por proyecto:

```powershell
.\SecretsManager.ps1 -Init
```

Agregar secretos:

```powershell
.\SecretsManager.ps1 -Add ApiUrl -Value "https://localhost:5001"
.\SecretsManager.ps1 -Add ApiKey -Value "dev-key"
```

Consumir desde scripts:

```powershell
$apiKeyExists = .\SecretsManager.ps1 -Exists ApiKey | ConvertFrom-Json
if (-not $apiKeyExists) {
    throw "ApiKey is not configured"
}
$apiKey = .\SecretsManager.ps1 -Get ApiKey | ConvertFrom-Json
```

Exportar JSON:

```powershell
.\SecretsManager.ps1 -List
```
