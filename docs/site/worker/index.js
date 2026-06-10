// Serves the static site, with one enhancement: for shared /try links that
// carry an input (?notes=...), it rewrites the social-preview metadata so an
// unfurl in Slack, Discord, iMessage, etc. shows the input notes and the top
// chord result. Crawlers do not run page JS, so the tags must be correct in
// the HTML response itself, which is what this Worker produces.
//
// The chord engine is the same compiled Dart bundle the browser uses; importing
// it for its side effects attaches globalThis.whatchordIdentify.
import "../js/chord-id.js";

const DEFAULT_MODE = "maj";
const DEFAULT_NOTATION = "textual";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Always start from the real static asset so non-meta content is untouched.
    const asset = await env.ASSETS.fetch(
      new Request(new URL("/try.html", url.origin), request),
    );

    const notes = (url.searchParams.get("notes") || "").trim();
    if (!notes) return asset;

    const key = url.searchParams.get("key") || "C:" + DEFAULT_MODE;
    const notation =
      url.searchParams.get("notation") === "symbolic"
        ? "symbolic"
        : DEFAULT_NOTATION;

    let meta;
    try {
      const result = JSON.parse(
        globalThis.whatchordIdentify(notes, key, notation),
      );
      meta = buildMeta(result, url);
    } catch {
      meta = null;
    }
    if (!meta) return asset;

    const out = new HTMLRewriter()
      .on("title", new Content(meta.titleTag))
      .on('meta[name="description"]', new Attr("content", meta.description))
      .on('meta[property="og:title"]', new Attr("content", meta.title))
      .on(
        'meta[property="og:description"]',
        new Attr("content", meta.description),
      )
      .on('meta[property="og:url"]', new Attr("content", meta.shareUrl))
      .on('meta[name="twitter:title"]', new Attr("content", meta.title))
      .on(
        'meta[name="twitter:description"]',
        new Attr("content", meta.description),
      )
      .transform(asset);

    // Per-URL response: let edge and crawler caches keep it for a while.
    const res = new Response(out.body, out);
    res.headers.set("Cache-Control", "public, max-age=3600");
    return res;
  },
};

// Builds preview copy from an engine result, or null when there is nothing
// worth previewing (bad input, or no candidates).
function buildMeta(result, url) {
  if (
    !result ||
    !result.ok ||
    !result.candidates ||
    !result.candidates.length
  ) {
    return null;
  }
  const notes = result.input.notes.join(" ");
  const top = result.candidates[0].symbol;
  const bass = result.input.bass;
  const key = result.input.key;
  const n = result.candidates.length;

  const title = notes + " → " + top;
  const description =
    "Identified with WhatChord's analysis engine. Bass " +
    bass +
    ", key " +
    key +
    ", top of " +
    n +
    " ranked candidate" +
    (n === 1 ? "" : "s") +
    ".";

  return {
    title,
    titleTag: title + " | WhatChord",
    description,
    shareUrl: url.href,
  };
}

// HTMLRewriter handler: overwrite an element's text content.
class Content {
  constructor(text) {
    this.text = text;
  }
  element(el) {
    el.setInnerContent(this.text);
  }
}

// HTMLRewriter handler: set an attribute's value.
class Attr {
  constructor(name, value) {
    this.name = name;
    this.value = value;
  }
  element(el) {
    el.setAttribute(this.name, this.value);
  }
}
