/** @type {import('stylelint').Config} */
export default {
  extends: ["stylelint-config-standard", "stylelint-config-recess-order"],
  rules: {
    "custom-property-empty-line-before": null,
    // Flags cross-section selectors that never overlap in practice (e.g.
    // footer links vs nav hover), so the reports here are false positives.
    "no-descending-specificity": null,
    // Hand-authored CSS with no Autoprefixer build step, so keep manual
    // vendor prefixes (e.g. -webkit-backdrop-filter for Safari < 18).
    "property-no-vendor-prefix": null,
    "value-no-vendor-prefix": null,
  },
  reportNeedlessDisables: true,
};
