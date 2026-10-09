//= require rails-ujs
//
// JS del admin. Se sirve con Sprockets (el admin no usa importmap ni Turbo),
// así que es JavaScript plano: rails-ujs para method/confirm en links y
// botones, más los comportamientos chicos del layout.
(function () {
  "use strict";

  function onReady(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  }

  // ── Sidebar en móvil ──────────────────────────────────────────────────
  function setupSidebar() {
    var sidebar = document.querySelector("[data-admin-sidebar]");
    var backdrop = document.querySelector("[data-admin-backdrop]");
    if (!sidebar) return;

    function open() {
      sidebar.classList.add("open");
      if (backdrop) backdrop.classList.remove("hidden");
      document.body.classList.add("overflow-hidden");
    }

    function close() {
      sidebar.classList.remove("open");
      if (backdrop) backdrop.classList.add("hidden");
      document.body.classList.remove("overflow-hidden");
    }

    document.querySelectorAll("[data-admin-menu-open]").forEach(function (el) {
      el.addEventListener("click", open);
    });
    document.querySelectorAll("[data-admin-menu-close]").forEach(function (el) {
      el.addEventListener("click", close);
    });
    document.addEventListener("keydown", function (event) {
      if (event.key === "Escape") close();
    });
  }

  // ── Tema claro / oscuro (el tema inicial lo aplica un script en <head>) ──
  function setupTheme() {
    function syncIcons() {
      var dark = document.documentElement.classList.contains("dark");
      document.querySelectorAll("[data-theme-sun]").forEach(function (el) {
        el.classList.toggle("hidden", dark);
      });
      document.querySelectorAll("[data-theme-moon]").forEach(function (el) {
        el.classList.toggle("hidden", !dark);
      });
    }

    document.querySelectorAll("[data-theme-toggle]").forEach(function (el) {
      el.addEventListener("click", function () {
        var next = document.documentElement.classList.contains("dark") ? "light" : "dark";
        document.documentElement.classList.toggle("dark", next === "dark");
        try { localStorage.setItem("admin-theme", next); } catch (_) {}
        syncIcons();
      });
    });
    syncIcons();
  }

  // ── Avisos (flash) que se cierran solos ───────────────────────────────
  function setupToasts() {
    document.querySelectorAll("[data-toast]").forEach(function (toast) {
      function dismiss() {
        toast.classList.add("is-leaving");
        setTimeout(function () { toast.remove(); }, 300);
      }
      var button = toast.querySelector("[data-toast-dismiss]");
      if (button) button.addEventListener("click", dismiss);
      setTimeout(dismiss, 5000);
    });
  }

  // ── Selects que filtran al cambiar (data-autosubmit) ──────────────────
  function setupAutosubmit() {
    document.querySelectorAll("[data-autosubmit]").forEach(function (el) {
      el.addEventListener("change", function () {
        if (el.form) el.form.requestSubmit ? el.form.requestSubmit() : el.form.submit();
      });
    });
  }

  // ── Vista previa del video de YouTube al pegar el link o el ID ────────
  function youtubeId(value) {
    value = (value || "").trim();
    var match = value.match(/(?:youtu\.be\/|youtube(?:-nocookie)?\.com\/(?:watch\?(?:.*&)?v=|embed\/|shorts\/|live\/|v\/))([\w-]{11})/);
    if (match) return match[1];
    return /^[\w-]{11}$/.test(value) ? value : null;
  }

  function setupYoutubePreview() {
    document.querySelectorAll("[data-youtube-input]").forEach(function (input) {
      var frame = document.getElementById(input.dataset.youtubeInput);
      if (!frame) return;
      function refresh() {
        var id = youtubeId(input.value);
        var iframe = frame.querySelector("iframe");
        if (!id) {
          frame.classList.add("hidden");
          return;
        }
        var src = "https://www.youtube.com/embed/" + id + "?rel=0";
        if (!iframe) {
          iframe = document.createElement("iframe");
          iframe.setAttribute("allow", "autoplay; fullscreen; picture-in-picture");
          iframe.setAttribute("allowfullscreen", "");
          iframe.setAttribute("title", "Vista previa del video");
          frame.appendChild(iframe);
        }
        if (iframe.getAttribute("src") !== src) iframe.setAttribute("src", src);
        frame.classList.remove("hidden");

        // La portada es la miniatura del video.
        var cover = document.querySelector("[data-youtube-cover]");
        if (cover) {
          var img = cover.querySelector("img");
          if (!img) {
            img = document.createElement("img");
            img.alt = "";
            cover.appendChild(img);
          }
          img.src = "https://i.ytimg.com/vi/" + id + "/hqdefault.jpg";
        }
      }
      input.addEventListener("input", refresh);
      input.addEventListener("change", refresh);
      input.addEventListener("blur", refresh);
    });
  }

  onReady(function () {
    setupSidebar();
    setupTheme();
    setupToasts();
    setupAutosubmit();
    setupYoutubePreview();
  });
})();
