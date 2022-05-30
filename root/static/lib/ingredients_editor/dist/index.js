import * as __SNOWPACK_ENV__ from '../_snowpack/env.js';
import.meta.env = __SNOWPACK_ENV__;

import React from "../_snowpack/pkg/react.js";
import ReactDOM from "../_snowpack/pkg/react-dom.js";
import IngredientsEditor from "./components/IngredientsEditor.js";
import "../_snowpack/pkg/bootstrap/dist/css/bootstrap.min.css.proxy.js";
const project = {
  type: ingredientsEditorData.dish_id ? "dish" : "recipe",
  id: ingredientsEditorData.project_id,
  name: ingredientsEditorData.project_name,
  specificId: ingredientsEditorData.dish_id || ingredientsEditorData.recipe_id
};
ReactDOM.render(/* @__PURE__ */ React.createElement(React.StrictMode, null, /* @__PURE__ */ React.createElement(IngredientsEditor, {
  project
})), document.getElementById("ingredients-editor"));
if (undefined /* [snowpack] import.meta.hot */ ) {
  undefined /* [snowpack] import.meta.hot */ .accept();
}
