import React from "../../_snowpack/pkg/react.js";
import {
  CheckBoxRounded,
  CheckBoxOutlineBlankRounded
} from "../../_snowpack/pkg/@material-ui/icons.js";
const AnimatedCheckBox = (props) => {
  return /* @__PURE__ */ React.createElement("div", {
    onClick: props.onCheck
  }, props.checked ? /* @__PURE__ */ React.createElement(CheckBoxRounded, {
    color: "primary"
  }) : /* @__PURE__ */ React.createElement(CheckBoxOutlineBlankRounded, null));
};
export default AnimatedCheckBox;
