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
        '<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.1" d="M10.6 13.4a4 4 0 0 1 0-5.7l2.8-2.8a4 4 0 0 1 5.7 5.7l-1.5 1.5"/>' +
        '<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.1" d="M13.4 10.6a4 4 0 0 1 0 5.7l-2.8 2.8a4 4 0 0 1-5.7-5.7l1.5-1.5"/>' +
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
