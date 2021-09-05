import React, {useCallback, useEffect, useState} from "../../_snowpack/pkg/react.js";
import {List} from "../util/List.js";
import Ingredient from "./Ingredient.js";
import IngredientListLimit from "./IngredientListLimit.js";
import {Card} from "../../_snowpack/pkg/react-bootstrap.js";
import {DndProvider} from "../../_snowpack/pkg/react-dnd.js";
import {HTML5Backend} from "../../_snowpack/pkg/react-dnd-html5-backend.js";
import "./IngredientsEditor.css.proxy.js";
import "../util/layout.css.proxy.js";
import IO from "../util/io.js";
const IngredientsEditor = ({
  project
}) => {
  const [nPIngredients, setNPIngredients] = useState([]);
  const [pIngredients, setPIngredients] = useState([]);
  const fetchIngredients = async () => {
    const normalIngrs = await IO.getAllNormalIngredients(project) || [];
    console.log("normalIngrs");
    console.log(normalIngrs);
    const preparedIngrs = await IO.getAllPreparedIngredients(project) || [];
    setNPIngredients(normalIngrs);
    setPIngredients(preparedIngrs);
  };
  useEffect(() => {
    fetchIngredients();
  }, []);
  const sortByPosition = (a, b) => a.position - b.position;
  const removeIngredient = useCallback((id) => {
    setNPIngredients((prevState) => prevState.filter((elem) => elem.id !== id));
    setPIngredients((prevState) => prevState.filter((elem) => elem.id !== id));
  }, [nPIngredients, pIngredients]);
  const updateIngredient = useCallback((id, newData) => {
    setNPIngredients((prevState) => prevState.map((elem) => elem.id === id ? {...elem, ...newData} : elem));
    setPIngredients((prevState) => prevState.map((elem) => elem.id === id ? {...elem, ...newData} : elem));
  }, [nPIngredients, pIngredients]);
  const equalsById = (ingr1) => (ingr2) => ingr1.id === ingr2.id;
  const moveIngredient = useCallback((source, target) => {
    if (List.contains(nPIngredients)(equalsById(source)) && List.contains(nPIngredients)(equalsById(target))) {
      setNPIngredients((prevState) => prevState.map((elem) => {
        if (elem.position === source.position) {
          return {
            ...elem,
            ...{
              position: target.position,
              prepare: false
            }
          };
        } else if (elem.position === target.position) {
          return {
            ...elem,
            ...{
              position: source.position,
              prepare: false
            }
          };
        } else {
          return elem;
        }
      }).sort(sortByPosition));
    } else if (List.contains(pIngredients)(equalsById(source)) && List.contains(nPIngredients)(equalsById(target))) {
      removeIngredient(source.id);
      setNPIngredients((prevState) => prevState.map((elem) => {
        if (elem.position >= target.position) {
          return {
            ...elem,
            ...{position: elem.position + 1}
          };
        } else {
          return elem;
        }
      }).concat([
        {
          ...source,
          ...{
            position: target.position,
            prepare: false
          }
        }
      ]).sort(sortByPosition));
    } else if (List.contains(nPIngredients)(equalsById(source)) && List.contains(pIngredients)(equalsById(target))) {
      removeIngredient(source.id);
      setPIngredients((prevState) => prevState.map((elem) => {
        if (elem.position >= target.position) {
          return {
            ...elem,
            ...{position: elem.position + 1}
          };
        } else {
          return elem;
        }
      }).concat([
        {
          ...source,
          ...{
            position: target.position,
            prepare: true
          }
        }
      ]).sort(sortByPosition));
    } else if (List.contains(pIngredients)(equalsById(source)) && List.contains(pIngredients)(equalsById(target))) {
      setPIngredients((prevState) => prevState.map((elem) => {
        if (elem.position === source.position) {
          return {
            ...elem,
            ...{
              position: target.position,
              prepare: true
            }
          };
        } else if (elem.position === target.position) {
          return {
            ...elem,
            ...{
              position: source.position,
              prepare: true
            }
          };
        } else {
          return elem;
        }
      }).sort(sortByPosition));
    }
  }, [nPIngredients, pIngredients]);
  const appendIngredientPrepared = (droppedIngredient) => {
    removeIngredient(droppedIngredient.id);
    setPIngredients((prevState) => prevState.concat([
      {
        ...droppedIngredient,
        ...{position: prevState.length + 1, prepare: true}
      }
    ]));
  };
  const prependIngredientPrepared = (droppedIngredient) => {
    removeIngredient(droppedIngredient.id);
    setPIngredients((prevState) => {
      let newState = prevState.map((elem) => ({...elem, ...{position: elem.position + 1}}));
      return [
        {
          ...droppedIngredient,
          ...{position: prevState.length, prepare: true}
        }
      ].concat(newState);
    });
  };
  const appendIngredientNotPrepared = (droppedIngredient) => {
    removeIngredient(droppedIngredient.id);
    setNPIngredients((prevState) => prevState.concat([
      {
        ...droppedIngredient,
        ...{position: prevState.length + 1, prepare: false}
      }
    ]));
  };
  const prependIngredientNotPrepared = (droppedIngredient) => {
    removeIngredient(droppedIngredient.id);
    setNPIngredients((prevState) => {
      let newState = prevState.map((elem) => ({...elem, ...{position: elem.position + 1}}));
      return [
        {
          ...droppedIngredient,
          ...{position: prevState.length, prepare: true}
        }
      ].concat(newState);
    });
  };
  return /* @__PURE__ */ React.createElement(Card, null, /* @__PURE__ */ React.createElement(Card.Header, null, /* @__PURE__ */ React.createElement("h3", null, "Ingredients")), /* @__PURE__ */ React.createElement(Card.Body, null, /* @__PURE__ */ React.createElement(DndProvider, {
    backend: HTML5Backend
  }, /* @__PURE__ */ React.createElement("div", {
    className: "flex flex-column align-start",
    id: "ingredients-editor"
  }, /* @__PURE__ */ React.createElement("div", {
    className: "list-header"
  }, "Normal Ingredients"), /* @__PURE__ */ React.createElement("div", {
    style: {width: "100%"},
    className: "flex flex-column align-start",
    id: "not-prepared-items"
  }, /* @__PURE__ */ React.createElement(IngredientListLimit, {
    appendIngredient: prependIngredientNotPrepared,
    size: {height: "1.5rem", width: "100%"},
    text: ""
  }), nPIngredients.map((ingr_def) => /* @__PURE__ */ React.createElement(Ingredient, {
    key: ingr_def.id,
    onDelete: removeIngredient,
    onChange: updateIngredient,
    moveIngredient,
    ingredient: ingr_def
  })), /* @__PURE__ */ React.createElement(IngredientListLimit, {
    appendIngredient: appendIngredientNotPrepared,
    size: {height: "3rem", width: "100%"},
    text: nPIngredients.length === 0 ? "There are no normal ingredients yet. Drag some ingredients here!" : ""
  })), /* @__PURE__ */ React.createElement("div", {
    className: "list-header"
  }, "Prepared Ingredients"), /* @__PURE__ */ React.createElement("div", {
    style: {width: "100%"},
    className: "flex flex-column align-start",
    id: "prepared-items"
  }, /* @__PURE__ */ React.createElement(IngredientListLimit, {
    appendIngredient: prependIngredientPrepared,
    size: {height: "1.5rem", width: "100%"},
    text: ""
  }), pIngredients.map((ingr_def) => /* @__PURE__ */ React.createElement(Ingredient, {
    key: ingr_def.id,
    onDelete: removeIngredient,
    onChange: updateIngredient,
    moveIngredient,
    ingredient: ingr_def
  })), /* @__PURE__ */ React.createElement(IngredientListLimit, {
    appendIngredient: appendIngredientPrepared,
    size: {height: "3rem", width: "100%"},
    text: pIngredients.length === 0 ? "There are no prepared ingredients yet. Drag some ingredients here to make them prepared!" : ""
  }))))));
};
export default IngredientsEditor;
