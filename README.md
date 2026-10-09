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
| Workouts | Catálogo: video de YouTube (link o ID), grupo muscular, duración, intensidad, material, Strength, día en el calendario, Estreno y portada |
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
* Los planes que se venden están en `app/models/plan.rb` (ID del precio de
  Stripe por plan). El checkout solo acepta esos precios; para cambiar un
  precio, crea el nuevo en Stripe y cambia su ID ahí.
* Un acceso de cortesía se da en **Admin → Usuarios → Editar → Acceso hasta**.

## Portadas de workouts

La portada de cada workout es la imagen que se suba en el admin; si no hay,
se usa la miniatura de su video de YouTube (`i.ytimg.com`, no requiere API
ni bucket). Una portada subida a un bucket que ya no está configurado (p. ej.
el de Bucketeer de la app anterior) también cae a la miniatura de YouTube.

## Variables de entorno (Heroku)

| Variable | Uso |
|---|---|
| `STRIPE_SECRET_KEY` | API key secreta de Stripe (`sk_live_...`) |
| `STRIPE_WEBHOOK_KEY` | Signing secret del webhook `/stripe/webhooks` (`whsec_...`). También se acepta `STRIPE_WEBHOOK_SECRET`. Sin ella el webhook responde 503 y Stripe reintenta |
| `POSTMARK_API_TOKEN` | Server API token de Postmark (correos de Devise; el remitente `hola@anagabyfitteam.com` o el dominio deben estar verificados) |
| `APP_HOST` | Dominio público de la app, para los links de los correos. Default: `anagabyfitteam.com` |
| `BUCKETEER_BUCKET_NAME`, `BUCKETEER_AWS_ACCESS_KEY_ID`, `BUCKETEER_AWS_SECRET_ACCESS_KEY`, `BUCKETEER_AWS_REGION` | Bucket de S3 para las portadas (add-on Bucketeer) |
| `AWS_BUCKET`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` | Alternativa a Bucketeer (un bucket propio) |
| `SECRET_KEY_BASE` | Lo crea solo el buildpack de Ruby. Sin él (ni `RAILS_MASTER_KEY`) la app no arranca |

Sin ningún bucket la app arranca igual, pero guarda las portadas subidas en
el disco del dyno, que Heroku borra en cada deploy o reinicio (el admin lo
avisa junto al campo de portada); mientras tanto se usan las miniaturas de
YouTube.

## Deploy

Las migraciones corren solas en cada deploy (release phase del `Procfile`).

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
