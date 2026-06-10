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

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    return;
  }

  document.querySelectorAll("[data-motion-media]").forEach(function (element) {
    var video = element.querySelector("[data-motion-video]");
    var toggle = element.querySelector("[data-motion-toggle]");
    if (!video) return;

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
          activateVideo();
          return;
        }

        video.pause();
        setPaused(true);
      });
    }

    if (video.readyState >= 3) {
      activateVideo();
    } else {
      video.addEventListener("canplay", activateVideo, { once: true });
    }
  });
})();
