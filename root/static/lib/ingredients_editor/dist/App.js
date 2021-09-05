import React, {useState, useEffect} from "../_snowpack/pkg/react.js";
import "./App.css.proxy.js";
function App({}) {
  const [count, setCount] = useState(0);
  useEffect(() => {
    const timer = setTimeout(() => setCount(count + 1), 1e3);
    return () => clearTimeout(timer);
  }, [count, setCount]);
  return /* @__PURE__ */ React.createElement("div", {
    className: "App"
  }, /* @__PURE__ */ React.createElement("header", {
    className: "App-header"
  }, /* @__PURE__ */ React.createElement("p", null, "Page has been open for ", /* @__PURE__ */ React.createElement("code", null, count), " seconds."), /* @__PURE__ */ React.createElement("p", null, /* @__PURE__ */ React.createElement("a", {
    className: "App-link",
    href: "https://reactjs.org",
    target: "_blank",
    rel: "noopener noreferrer"
  }, "Learn React"))));
}
export default App;
