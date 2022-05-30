// [snowpack] add styles to the page (skip if no document exists)
if (typeof document !== 'undefined') {
  const code = ".flex {\n    display: flex;\n}\n\n.flex-column {\n    flex-direction: column;\n}\n\n.flex-row {\n    flex-direction: row;\n}\n\n.align-center {\n    align-items: center;\n}\n\n.justify-center {\n    justify-items: center;\n}\n\n.align-start {\n    align-items: start;\n}\n\n.justify-start {\n    justify-items: start;\n}\n\n.grid {\n    display: grid;\n}\n\n.scrollable-y {\n    overflow-y: scroll;\n    scrollbar-color: black;\n    scrollbar-width: thin;\n}\n\n.truncate {\n    white-space: nowrap;\n    overflow: hidden;\n    text-overflow: ellipsis;\n}\n\n.ml-truncate {\n    overflow: hidden;\n    display: -webkit-box;\n    -webkit-box-orient: vertical;\n}";

  const styleEl = document.createElement("style");
  const codeEl = document.createTextNode(code);
  styleEl.type = 'text/css';
  styleEl.appendChild(codeEl);
  document.head.appendChild(styleEl);
}