---
name: frontend-backend-db-map
description: Mapea campos visibles de un formulario frontend hasta propiedades backend y columnas de base de datos verificadas. Requiere $1 para ubicar el formulario y $2 para indicar la ruta del backend; entrega una lista por secciones para Alta y Actualizar.
---

# Mapeo Frontend → Backend → Base de datos

Usa esta skill cuando se pida identificar la correspondencia de los campos de un formulario con el contrato backend y las columnas declaradas en las entidades. Es una tarea de lectura: no modifica código, datos ni servicios.

## Entradas obligatorias

- `$1`: captura adjunta, ruta de página frontend, nombre de formulario o descripción suficiente para localizarlo. Una captura sirve para reconocer campos y ubicación; confirma el componente efectivo en el código.
- `$2`: ruta accesible del backend que atiende el formulario. Puede apuntar a un módulo; sigue sus dependencias y entidades compartidas dentro del mismo repositorio.

Antes de iniciar el mapeo, comprueba que ambas entradas estén presentes y permitan localizar sus fuentes. Si falta alguna, no es accesible o `$1` coincide con varios formularios sin poder distinguir el objetivo, solicita únicamente el dato necesario. No reemplaces `$1` con la pestaña activa del navegador ni con el archivo abierto en el IDE; tampoco infieras `$2` de un mapeo anterior.

## Trazabilidad

1. Localiza la ruta, página y componente que renderizan el formulario. Delimita sus secciones y enumera los campos visibles, incluidos los de solo lectura. Obtén cada nombre de su etiqueta y cada modelo de su enlace real; no uses los valores personales de una captura. Si las etiquetas, los identificadores de preguntas o el anexo llegan desde un endpoint, comprueba esa respuesta o su fuente de catálogo antes de listarlos.
2. Revisa Alta y Actualizar, salvo que el usuario limite la operación. Para cada campo, sigue su modelo o fuente hasta el método de guardado, transformaciones, payload y endpoint efectivo. Identifica por separado los datos de solo lectura que llegan mediante una relación o consulta.
3. Desde el endpoint, sigue el DTO o contrato, servicio, mapper y entidad o SQL hasta la tabla y columna reales. Si `$2` es un módulo, continúa por los imports hacia módulos compartidos del repositorio. Para claves foráneas y selecciones múltiples, verifica la relación y la tabla intermedia cuando exista.
4. Confirma una correspondencia solo cuando el flujo observado la sostiene. Un nombre parecido en el DTO o la entidad no basta. Si el componente, una rama, el contrato o la columna no permiten demostrar un tramo, escribe `No verificado` en esa celda. No atribuyas a un campo visible valores constantes, generados o de auditoría que el usuario no introduce.

## Salida

Inicia la salida con el rótulo **Formato: Frontend → Backend → Base de datos** una sola vez. Después entrega una lista Markdown agrupada en el mismo orden y con los mismos nombres de secciones que muestra el formulario. No uses tablas ni repitas los rótulos en cada elemento. Cada campo y cada pregunta tiene su propia viñeta, con los tres valores en ese orden y en una línea. Para preguntas, copia el nombre que renderiza el frontend y agrega el identificador individual `(idPregunta: N)`; no agrupes IDs ni uses rangos. Dentro de cada sección del formulario, agrupa las preguntas bajo un encabezado `Anexo N`, identificado desde la configuración del frontend o la fuente efectiva de preguntas. Si una sección contiene preguntas de varios anexos, crea un encabezado separado para cada anexo y conserva el orden en que aparecen en el formulario. Si no puedes demostrar el anexo, usa el encabezado `Anexo no verificado`.

Ejemplo:

**Formato: Frontend → Backend → Base de datos**

- **Datos del cuidador**
  - Departamento del cuidador (`departamentoCuidador`) → `integrantesFamilia[].idDepartamento` → `SSI_FAMILIA_INTEGRANTES.UBI_ID_DEPARTAMENTO`
- **Para Niña, Niño y Adolescente**
  - **Anexo 9**
    - *Nombre exacto de la pregunta* (`idPregunta: 404`) → `anexosRespuestas[].respuesta` → `SSI_ANEXOS_RESPUESTAS.AR_RESPUESTA` (relación de pregunta: `AP_ID_PREGUNTA`)

Usa la etiqueta visible y, entre paréntesis, el modelo frontend cuando se haya identificado. Para preguntas, conserva exactamente el texto del campo renderizado y su `idPregunta`. En Backend, escribe la propiedad exacta del contrato; para un dato de solo lectura, indica la propiedad de la relación que lo suministra y la clave que la vincula. En Base de datos, usa `TABLA.COLUMNA`; si el valor procede de otra tabla, muestra de forma breve la clave de enlace. Consolida correspondencias iguales de Alta y Actualizar; indica `(Alta)` o `(Actualizar)` junto al campo solo si sus correspondencias difieren. Mantén `No verificado` para cada tramo sin equivalencia demostrable. No agregues análisis, recomendaciones ni datos personales.
