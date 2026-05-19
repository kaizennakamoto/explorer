// Liberty Chain: hardcode gas price display to "0 Gwei"
(function() {
  function fix() {
    var els = document.querySelectorAll("span, p, div, a, td");
    for (var i = 0; i < els.length; i++) {
      var el = els[i];
      if (el.children.length === 0) {
        var t = el.textContent.trim();
        if (t.indexOf("Gwei") !== -1 && t !== "0 Gwei") {
          el.textContent = "0 Gwei";
        }
        if (t === "Blockscout is a tool for inspecting and analyzing EVM based blockchains.") {
          el.textContent = "";
        }
        if (t === "Blockchain explorer for Ethereum Networks.") {
          el.textContent = "";
        }
      }
    }
  }
  var obs = new MutationObserver(fix);
  function start() {
    obs.observe(document.body, { childList: true, subtree: true });
    fix();
  }
  if (document.body) start();
  else document.addEventListener("DOMContentLoaded", start);
  setTimeout(fix, 1000);
  setTimeout(fix, 3000);
  setTimeout(fix, 6000);
})();
