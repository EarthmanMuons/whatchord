// Shared behavior for the static site.
(function () {
  "use strict";

  var androidDialog = document.getElementById("android-dialog");
  if (androidDialog) {
    function openAndroidDialog(event) {
      event.preventDefault();
      androidDialog.showModal();
    }

    document
      .querySelectorAll("[data-android-beta]")
      .forEach(function (element) {
        element.addEventListener("click", openAndroidDialog);
      });

    document
      .querySelectorAll("[data-close-android-dialog]")
      .forEach(function (element) {
        element.addEventListener("click", function () {
          androidDialog.close();
        });
      });

    if (/android/i.test(navigator.userAgent)) {
      document.querySelectorAll(".btn-get-app").forEach(function (element) {
        element.href = "#";
        element.addEventListener("click", openAndroidDialog);
      });
    }
  }

  // Give article section headings GitHub-style anchor links, generating ids
  // from the heading text so no article has to hand-author them.
  var articleBody = document.querySelector(".article-body");
  if (articleBody) {
    var usedIds = {};
    articleBody.querySelectorAll("h2").forEach(function (heading) {
      // Leave the call-to-action and related-articles headings alone.
      if (heading.closest(".article-cta, .article-related")) return;

      var slug = heading.textContent
        .trim()
        .toLowerCase()
        .replace(/[^\w\s-]/g, "")
        .replace(/\s+/g, "-")
        .replace(/-+/g, "-");
      if (!slug) return;

      usedIds[slug] = (usedIds[slug] || 0) + 1;
      if (usedIds[slug] > 1) slug = slug + "-" + usedIds[slug];
      if (!heading.id) heading.id = slug;

      var anchor = document.createElement("a");
      anchor.className = "heading-anchor";
      anchor.href = "#" + heading.id;
      anchor.setAttribute("aria-label", "Link to this section");
      anchor.innerHTML =
        '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">' +
        '<path d="M3.9 12a3.1 3.1 0 0 1 3.1-3.1h4V7H7a5 5 0 0 0 0 10h4v-1.9H7A3.1 3.1 0 0 1 3.9 12zm4.1 1h8v-2H8v2zm9-6h-4v1.9h4a3.1 3.1 0 0 1 0 6.2h-4V17h4a5 5 0 0 0 0-10z"/>' +
        "</svg>";
      heading.appendChild(anchor);
    });
  }

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    return;
  }

  document.querySelectorAll("[data-motion-media]").forEach(function (element) {
    var video = element.querySelector("[data-motion-video]");
    var toggle = element.querySelector("[data-motion-toggle]");
    if (!video) return;

    var userPaused = false;

    function setPaused(isPaused) {
      element.classList.toggle("is-video-paused", isPaused);
      if (toggle) {
        toggle.setAttribute(
          "aria-label",
          isPaused ? "Play animation" : "Pause animation",
        );
      }
    }

    function activateVideoControl() {
      element.classList.add("is-video-active");
      setPaused(video.paused);
      if (toggle) {
        toggle.hidden = false;
      }
    }

    function activateVideo() {
      var play = video.play();
      if (play && typeof play.then === "function") {
        play.then(activateVideoControl).catch(function () {});
        return;
      }

      activateVideoControl();
    }

    if (toggle) {
      toggle.addEventListener("click", function () {
        if (video.paused) {
          userPaused = false;
          activateVideo();
          return;
        }

        userPaused = true;
        video.pause();
        setPaused(true);
      });
    }

    // Only run the video while it is on screen, and respect a manual pause
    // when scrolling back into view.
    if ("IntersectionObserver" in window) {
      new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting) {
              if (!userPaused) activateVideo();
            } else {
              video.pause();
            }
          });
        },
        { threshold: 0.25 },
      ).observe(element);
    } else if (video.readyState >= 3) {
      activateVideo();
    } else {
      video.addEventListener("canplay", activateVideo, { once: true });
    }
  });
})();
