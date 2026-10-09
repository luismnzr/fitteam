# Fitteam

Plataforma de clases en video de Ana Gaby Ornelas (anagabyfitteam.com):
catálogo de workouts, calendario con el "Workout del día", favoritas,
comentarios y suscripción con Stripe.

## Admin (`/admin`)

Panel para administrar el sitio, con el mismo lenguaje visual que el admin de
Eclipse (y que el de Sculpt by Lore). Solo entran usuarias con `admin = true`
(las demás regresan al inicio); a las admins les aparece el link "Admin" en
la navegación del sitio.

| Sección | Qué se administra |
|---|---|
| Panel | Usuarios con acceso, registros, accesos por vencer, la semana del calendario, favoritas del mes, comentarios y registros recientes |
| Workouts | Catálogo: video de YouTube (link o ID; su miniatura es la portada), grupo muscular, duración, intensidad, material, Strength, día en el calendario y Estreno |
| Calendario | Mes completo con el workout de cada día; "+" en un día crea un workout ya programado |
| Usuarios | Búsqueda, acceso (Stripe o cortesía con fecha), rol de admin, correo para nueva contraseña, links a Stripe |
| Comentarios | Bandeja de comentarios sin responder; responder como Ana Gaby o borrar |

**El sitio público es de solo lectura**: crear, editar y borrar workouts
solo existe dentro de `/admin` (`Admin::BaseController` exige sesión y rol de
admin). Los links "Agregar clase" y "Editar clase" que ven las admins en el
sitio apuntan al admin. El admin anterior (Administrate) se quitó.

Para dar el rol de admin a alguien por primera vez:

```
heroku run rails runner 'User.find_by!(email: "correo@ejemplo.com").update!(admin: true)'
```

Después se maneja desde **Admin → Usuarios → Editar**.

### CSS del admin (Tailwind 4)

El admin tiene su propio CSS, separado del sitio: la fuente está en
`tools/admin-css/admin.css` y el resultado compilado se **commitea** en
`app/assets/builds/admin.css` (en Heroku no corre Tailwind; Sprockets solo
le pone el digest como a cualquier otro asset). Después de cambiar clases en
`app/views/admin`, el layout del admin o `app/helpers/admin_helper.rb`:

```
bin/admin_css           # compila una vez (la primera vez instala Tailwind en tools/admin-css)
bin/admin_css --watch   # recompila mientras editas
```

Producción y test no usan el compresor de libsass (`css_compressor = nil`):
libsass no entiende el CSS moderno de Tailwind 4. El SCSS del sitio se sigue
sirviendo comprimido porque `config.sass.style = :compressed`.

El admin no usa importmap ni Turbo: su JS (`app/assets/javascripts/admin.js`)
es JavaScript plano servido por Sprockets, con rails-ujs para los botones de
borrar y las confirmaciones.

## Acceso y suscripciones (Stripe)

* El acceso a las clases lo decide `users.subscription_ends_at`
  (`User#active?`). Las admins ven las clases aunque no tengan suscripción.
* El webhook `/stripe/webhooks` lo mantiene al día y **solo acepta eventos
  firmados** con `STRIPE_WEBHOOK_KEY`. En Stripe, el endpoint debe enviar:
  `customer.created`, `customer.subscription.created`,
  `customer.subscription.updated` y `customer.subscription.deleted`.
  * `active`, `trialing` y `past_due` dan acceso hasta el fin del periodo.
  * `unpaid`, `canceled`, `paused`, etc. quitan el acceso.
  * Cancelar una suscripción vieja no le quita el acceso a la actual
    (`users.subscription_id`).
* Los planes que se venden están en `app/models/plan.rb`: nombre, precio que
  se muestra e ID del precio de Stripe. La página de planes y la home los
  pintan desde ahí (`payments/_plans`). El checkout solo acepta esos precios;
  para cambiar un precio, crea el nuevo en Stripe y cambia su ID y su texto
  ahí.
* Un acceso de cortesía se da en **Admin → Usuarios → Editar → Acceso hasta**.

## Portadas de workouts (YouTube)

La portada de cada workout es la miniatura de su video de YouTube; ya no se
suben imágenes. Al guardar un workout en el admin se busca la de mejor
calidad que exista (`maxresdefault` 1280px → `sddefault` → `hqdefault`) y se
guarda su URL en `workouts.thumbnail_url` (`YoutubeThumbnail`, sin API key).
Mientras un workout no la tenga, se usa `hqdefault`, que existe para todos
los videos. Para cambiar una portada basta con cambiar la miniatura del
video en YouTube.

Las miniaturas se sirven desde la app (`/workouts/:id/thumbnail/card|cover`,
`WorkoutThumbnailsController`), nunca desde `i.ytimg.com`: esa URL trae el ID
del video, y con él cualquiera sin plan podría ver la clase en YouTube. La
app la descarga, la guarda en caché 7 días y el navegador 30 días. Las
miniaturas 4:3 (`hqdefault`/`sddefault`) traen barras negras que
`WorkoutsHelper#workout_media` recorta en cualquier proporción.

Para llenar las de todos los workouts de una vez (después del deploy que
agrega `thumbnail_url`, o de un restore):

```
heroku run rails youtube:thumbnails           # las que faltan
heroku run FORCE=1 rails youtube:thumbnails   # todas
```

Al final lista los workouts cuyo video no es un link de YouTube o ya no
existe.

## Variables de entorno (Heroku)

| Variable | Uso |
|---|---|
| `STRIPE_SECRET_KEY` | API key secreta de Stripe (`sk_live_...`) |
| `STRIPE_WEBHOOK_KEY` | Signing secret del webhook `/stripe/webhooks` (`whsec_...`). También se acepta `STRIPE_WEBHOOK_SECRET`. Sin ella el webhook responde 503 y Stripe reintenta |
| `SMTP_PASSWORD` | Token de Mailtrap (sending, `live.smtp.mailtrap.io`). Es el correo mientras no haya `POSTMARK_API_TOKEN`. Opcionales: `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME` (o `SMTP_USER_NAME`) (por defecto, los de Mailtrap) |
| `POSTMARK_API_TOKEN` | Server API token de Postmark. Si existe, los correos salen por Postmark en lugar de SMTP (el remitente `hola@anagabyfitteam.com` o el dominio deben estar verificados en Postmark) |
| `APP_HOST` | Dominio público de la app, para los links de los correos. Default: `anagabyfitteam.com` |
| `SECRET_KEY_BASE` | Lo crea solo el buildpack de Ruby. Sin él (ni `RAILS_MASTER_KEY`) la app no arranca |

La app no sube archivos, así que no necesita bucket de S3 (el add-on
Bucketeer se puede quitar).

## Deploy

Las migraciones corren solas en cada deploy (release phase del `Procfile`).

## Sitio público: assets y JavaScript

* Las librerías externas se cargan solo en la página que las usa: Swiper
  (carruseles) en `/workouts` y FullCalendar en `/calendario`, con versión
  fija. El sitio ya no usa jQuery.
* El calendario pide a `/workouts.json` solo los workouts con fecha del mes
  visible.
* Las tarjetas del catálogo (`workouts/_workout`) usan la miniatura de
  480px (`Workout#card_image_url`); la de mejor calidad se reserva para el
  banner de destacados y la página de cada clase.
* En la página de cada clase el video se reproduce en la misma página (sin
  popup) y abajo salen 3 clases más del mismo grupo muscular.
* Las imágenes de `app/assets/images` están comprimidas (fondos a 2000px
  máximo, días de la semana en WebP). Si agregas una nueva, comprímela antes
  de subirla.

## CI

GitHub Actions corre RuboCop, Brakeman, `importmap audit` y los tests.
`config/brakeman.ignore` silencia tres avisos con su nota: el permiso de
admin en el admin (intencional) y el fin de soporte de Ruby 3.1 y Rails 7.2,
que se quitan al actualizar (`bin/brakeman` vuelve a llevar
`--ensure-latest` entonces).

## Desarrollo y tests

```
bin/rails db:prepare
bin/rails server
bin/rails test
```

Los tests cubren el acceso al admin por rol y sus escrituras, que el sitio
público no tenga rutas de escritura, que el formulario de cuenta no permita
darse acceso ni volverse admin, el checkout y el webhook de Stripe, y los
correos y mensajes de Devise en español.

En local los correos no se envían: quedan en el log del servidor.
