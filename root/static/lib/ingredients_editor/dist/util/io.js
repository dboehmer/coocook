import {backend} from "../constants.js";
const baseUrl = (project) => {
  switch (project.type) {
    case "dish":
      return `${backend}/project/${project.id}/${project.name}/dish/${project.specificId}`;
    case "recipe":
      return `${backend}/project/${project.id}/${project.name}/recipe/${project.specificId}`;
  }
};
const initialIngredientTransformation = (ingredient) => ({
  ...ingredient,
  ...{
    beingDragged: false,
    units: [ingredient.current_unit, ...ingredient.units]
  }
});
const getAllNormalIngredients = async (project) => {
  try {
    const response = await (await fetch(`${baseUrl(project)}/ingredients`)).json();
    const final = response.map(initialIngredientTransformation);
    console.log("final");
    console.log(final);
    return final;
  } catch (err) {
    console.error(err);
    return null;
  }
};
const getAllPreparedIngredients = async (project) => {
  try {
    const response = await (await fetch(`${baseUrl(project)}/ingredients`)).json();
    return response.data.map(initialIngredientTransformation);
  } catch (err) {
    return null;
  }
};
const createIngredient = async (project, ingredient) => {
  try {
    const response = await fetch(`${baseUrl(project)}/ingredients`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(ingredient)
    });
    const id = (await response.json()).data;
    if (!isNaN(id)) {
      return id;
    } else {
      return null;
    }
  } catch (err) {
    return null;
  }
};
const putIngredient = async (project, ingredient) => {
  try {
    const response = await fetch(`${baseUrl(project)}/ingredients/${ingredient.id}`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(ingredient)
    });
    await response.json();
    return ingredient.id;
  } catch (err) {
    return null;
  }
};
const deleteIngredient = async (project, ingredient) => {
  try {
    const response = await fetch(`${baseUrl(project)}/ingredients/${ingredient.id}`, {
      method: "DELETE"
    });
    await response.json();
    return ingredient.id;
  } catch (err) {
    return null;
  }
};
const IO = {
  getAllNormalIngredients,
  getAllPreparedIngredients,
  createIngredient,
  putIngredient,
  deleteIngredient
};
export default IO;
