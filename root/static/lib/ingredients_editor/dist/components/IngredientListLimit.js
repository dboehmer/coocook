import React from "../../_snowpack/pkg/react.js";
import {DragTypes} from "../util/DragDefs.js";
import {useDrop} from "../../_snowpack/pkg/react-dnd.js";
const IngredientListLimit = ({
  text,
  size,
  appendIngredient
}) => {
  const [, drop] = useDrop({
    accept: DragTypes.Ingredient,
    hover(item, monitor) {
      appendIngredient(item.ingredient);
    }
  });
  return /* @__PURE__ */ React.createElement("div", {
    ref: drop,
    style: {height: size.height, width: size.width}
  }, text);
};
export default IngredientListLimit;
