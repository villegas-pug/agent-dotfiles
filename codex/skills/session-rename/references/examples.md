# Ejemplos de session-rename

Cada bloque muestra el contexto y la salida esperada. Todos cumplen el formato de `SKILL.md`.

## Login en el panel de admin

**Contexto:** "En esta sesión agregué login con credenciales al panel de admin."

```
**Recomendado:** `auth-credentials-add`

1. `auth-credentials-add` — describe el cambio de credenciales.
2. `admin-login-wire` — enfoca el área admin y la integración del login.
3. `auth-setup` — versión corta si hubo varias tareas de auth.
```

## Refactor del carrito a Zustand

**Contexto:** "Refactoricé el carrito para usar Zustand en lugar de Context."

```
**Recomendado:** `cart-zustand-migrate`

1. `cart-zustand-migrate` — captura la tecnología destino y el cambio.
2. `cart-state-refactor` — versión genérica del refactor de estado.
3. `cart-state-migrate` — mismo cambio con foco en el estado.
```

## Integración de Stripe

**Contexto:** "Integré Stripe para procesar pagos en el checkout."

```
**Recomendado:** `payment-stripe-integrate`

1. `payment-stripe-integrate` — incluye proveedor y acción.
2. `checkout-stripe-wire` — vista desde el módulo checkout.
3. `payment-stripe-add` — variante más corta con `add`.
```

## Bug en el cálculo de envío

**Contexto:** "Corregí un bug en el cálculo de envío del carrito."

```
**Recomendado:** `cart-shipping-fix`

1. `cart-shipping-fix` — área principal, sub-área y acción.
2. `shipping-cart-fix` — invierte el orden si `shipping` es el área principal.
3. `cart-shipping-debug` — útil si la causa aún no está confirmada.
```

## Sesión multitema

**Contexto:** "Agregué el login del admin, arreglé el cálculo de envío y migré el carrito a Zustand; el login fue lo último que hice."

```
**Recomendado:** `auth-credentials-add`

1. `auth-credentials-add` — tema que cerró la sesión.
2. `cart-zustand-migrate` — otro tema de la sesión; no se mezcla en el nombre.
3. `cart-shipping-fix` — tercer tema de la sesión.
```

## Anti-ejemplos (NO hacer)

- `Auth-Fix` → mayúsculas prohibidas.
- `cart_fix` → guion bajo prohibido.
- `auth-fix-` → guion final prohibido.
- `Pago-Stripe` → acento y mayúsculas prohibidas.
- `added-login-feature` → debe empezar por `feature`, no por un verbo en pasado.
- `cart-bug-fix-shipping` → `bug` no es acción del vocabulario; usa `cart-shipping-fix`.
- `state-cart-zustand` → no termina en acción; usa `cart-zustand-migrate`.
- `payment-stripe-integration` → `integration` es sustantivo; usa la acción `integrate`.
