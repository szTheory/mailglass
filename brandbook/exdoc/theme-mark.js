(() => {
  const logo = document.querySelector(".sidebar-projectImage img");
  if (!logo || !document.body) return;

  const updateMark = () => {
    const asset = document.body.classList.contains("dark")
      ? "assets/mailglass-mark-dark.svg"
      : "assets/mailglass-mark-light.svg";

    if (!logo.getAttribute("src")?.endsWith(asset)) logo.setAttribute("src", asset);
  };

  updateMark();
  new MutationObserver(updateMark).observe(document.body, {
    attributes: true,
    attributeFilter: ["class"],
  });
})();
