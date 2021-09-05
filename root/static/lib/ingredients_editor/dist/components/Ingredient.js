import React, {useRef} from "../../_snowpack/pkg/react.js";
import {Button, Form, Popover} from "../../_snowpack/pkg/react-bootstrap.js";
import {DeleteRounded, DragIndicator} from "../../_snowpack/pkg/@material-ui/icons.js";
import {useDrag, useDrop} from "../../_snowpack/pkg/react-dnd.js";
import {DragTypes} from "../util/DragDefs.js";
import "../util/layout.css.proxy.js";
const ingredientStyle = {
  border: "solid 2px grey",
  padding: "4px",
  borderRadius: "4px",
  width: "100%",
  height: "3rem"
};
const Ingredient = ({
  ingredient: data,
  onDelete,
  onChange,
  moveIngredient
}) => {
  const ref = useRef(null);
  const handle = useRef(null);
  const [, drop] = useDrop({
    accept: DragTypes.Ingredient,
    hover(item, monitor) {
      if (!ref.current) {
        return;
      }
      const dragPosition = item.ingredient.position;
      const hoverPosition = data.position;
      const sameList = item.ingredient.prepare === data.prepare;
      if (sameList && dragPosition === hoverPosition) {
        return;
      }
      const hoverBoundingRect = ref.current?.getBoundingClientRect();
      const hoverMiddleY = (hoverBoundingRect.bottom - hoverBoundingRect.top) / 2;
      const clientOffset = monitor.getClientOffset();
      const hoverClientY = clientOffset.y - hoverBoundingRect.top;
      if (sameList && dragPosition < hoverPosition && hoverClientY < hoverMiddleY) {
        return;
      }
      if (sameList && dragPosition > hoverPosition && hoverClientY > hoverMiddleY) {
        return;
      }
      moveIngredient(item.ingredient, data);
      item.ingredient.position = hoverPosition;
    }
  });
  const [{isDragging}, drag, preview] = useDrag({
    item: {
      type: DragTypes.Ingredient,
      id: data.id,
      ingredient: {...data, ...{beingDragged: true}}
    },
    collect: (monitor) => ({
      isDragging: monitor.isDragging()
    }),
    end: (item, monitor) => {
      if (item !== void 0) {
        onChange(item.id, {beingDragged: false});
      }
    }
  });
  const FullComment = (props) => {
    return /* @__PURE__ */ React.createElement(Popover, {
      id: "popover-basic",
      content: true,
      ...props
    });
  };
  preview(drop(ref));
  drag(handle);
  const dragStyle = {
    border: "dashed 2px grey",
    opacity: 0.5
  };
  return /* @__PURE__ */ React.createElement("div", {
    ref,
    className: "flex flex-row align-center justify-center",
    style: isDragging || data.beingDragged ? {...ingredientStyle, ...dragStyle} : {...ingredientStyle}
  }, /* @__PURE__ */ React.createElement("div", {
    ref: handle,
    style: {flex: "none", cursor: "move"}
  }, /* @__PURE__ */ React.createElement(DragIndicator, {
    fontSize: "large",
    style: {color: "grey"}
  })), /* @__PURE__ */ React.createElement("div", {
    style: {minWidth: "8rem", flex: "none"}
  }, data.article.name), /* @__PURE__ */ React.createElement("div", {
    style: {width: "4.6rem", flex: "none"}
  }, /* @__PURE__ */ React.createElement(Form, null, /* @__PURE__ */ React.createElement(Form.Control, {
    as: "input",
    type: "number",
    step: "any",
    defaultValue: data.value,
    onChange: (e) => {
      const target = e.target;
      onChange(data.id, Object.assign(data, {
        value: Number.parseFloat(target.value)
      }));
    }
  }))), /* @__PURE__ */ React.createElement("div", {
    style: {width: "6.5rem", flex: "none"}
  }, /* @__PURE__ */ React.createElement(Form.Control, {
    as: "select",
    defaultValue: data.current_unit.id,
    onChange: (e) => {
      onChange(data.id, Object.assign(data, {
        current_unit: data.units.find((u) => u.id === Number.parseInt(e.target.value))
      }));
    }
  }, data.units.map((unit) => /* @__PURE__ */ React.createElement("option", {
    key: unit.id,
    value: unit.id
  }, unit.short_name, " (", unit.long_name, ")")))), /* @__PURE__ */ React.createElement(Form.Control, {
    as: "input",
    type: "text",
    defaultValue: data.comment
  }), /* @__PURE__ */ React.createElement("div", {
    style: {flex: "none"}
  }, /* @__PURE__ */ React.createElement(Button, {
    variant: "danger",
    onClick: () => onDelete(data.id)
  }, /* @__PURE__ */ React.createElement(DeleteRounded, null))));
};
export default Ingredient;
