---
name: hybrid-email-format
description: Genera y aplica correos profesionales con formato híbrido HTML para Gmail, combinando encabezado visual, resumen ejecutivo, secciones, listas, tablas y bloques destacados. Úsalo al redactar o mejorar un correo cuyo diseño, legibilidad y presentación profesional sean importantes.
---

# Hybrid Email Format

Diseña correos claros y visualmente atractivos con HTML compatible con clientes de correo. El formato híbrido combina estructura ejecutiva, elementos técnicos y una presentación visual sobria.

## Resultado predeterminado

Genera el HTML completo y, si el usuario lo solicita y el arnés tiene acceso a un borrador de Gmail, aplícalo al cuerpo del borrador. Mantén el mensaje como borrador: nunca lo envíes automáticamente.

La estructura predeterminada es:

1. Encabezado destacado con título, subtítulo e identidad visual.
2. Icono técnico inline relacionado con programación, por ejemplo `</>`, terminal o circuito.
3. Etiqueta de rol: `Analista Programador`.
4. Bloque de `Resumen ejecutivo`.
5. Saludo e introducción breve.
6. Secciones con títulos y separadores sutiles.
7. Lista con viñetas para capacidades o características.
8. Tabla comparativa solo cuando existan datos suficientes para comparar.
9. Lista numerada para aplicaciones, pasos o próximos usos.
10. Bloque destacado de `Próximo paso` o recomendación.
11. Cierre y firma completa.
12. Nota breve de contexto o disponibilidad cuando sea pertinente.

## Identidad y estilo

- Firma predeterminada:

  `Rooy Cristopher Guevara Villegas`  
  `Analista Programador`

- Usa una paleta sobria por defecto: azul marino para el encabezado, azul claro para información y verde suave para acciones o próximos pasos.
- Mantén un ancho legible, normalmente entre 600 y 680 px, con espacios amplios y jerarquía tipográfica clara.
- Usa estilos inline, tablas para bloques estructurales y fuentes del sistema como Arial, Helvetica o sans-serif.
- Evita JavaScript, formularios, fuentes externas, imágenes remotas, CSS complejo y SVG dependiente de recursos externos.
- El icono técnico debe ser texto o HTML inline; no debe requerir descargar un archivo.
- Si el usuario proporciona un logo gráfico, puede sustituir al icono predeterminado, pero conserva una alternativa textual accesible.

## Reglas de contenido

- No inventes nombres, versiones, capacidades, cifras ni anuncios de productos.
- Si faltan datos verificables, usa lenguaje neutral, marcadores como `[confirmar versión]` o indica que el contenido es hipotético.
- No presentes como confirmado un modelo, producto o característica solo porque aparezca en el texto del usuario.
- Adapta el tono, longitud, colores, branding, icono y secciones a la solicitud; la estructura anterior es un punto de partida, no una obligación rígida.
- No añadas una tabla si solo repite el texto o si no hay una comparación real.
- Prioriza accesibilidad: títulos descriptivos, buen contraste, texto alternativo cuando haya imágenes y tablas con encabezados claros.

## Aplicación a Gmail

Solo cuando tengas acceso a un borrador compatible en Gmail:

1. Inspecciona el borrador antes de modificarlo y conserva destinatarios y asunto salvo petición expresa.
2. Selecciona el área visible del cuerpo del mensaje.
3. Inserta el contenido como HTML enriquecido, no como texto literal con etiquetas.
4. Verifica visualmente el encabezado, el icono, las listas, la tabla, los bloques destacados y la firma.
5. Confirma que el borrador siga abierto y no ejecutes ninguna acción de envío.

Si no es posible editar Gmail, entrega el HTML completo y un fallback en Markdown o texto plano, explicando brevemente cómo usar cada versión.

## Validación antes de entregar

Comprueba que:

- el HTML sea autosuficiente y use estilos inline;
- no contenga scripts, dependencias externas ni recursos inseguros;
- la firma incluya exactamente `Rooy Cristopher Guevara Villegas` y `Analista Programador`;
- el icono técnico sea visible sin imágenes externas;
- los datos inciertos estén marcados o redactados de forma neutral;
- el contenido siga siendo legible en una vista estrecha;
- Gmail conserve destinatario y asunto y el mensaje permanezca como borrador si lo editaste.
