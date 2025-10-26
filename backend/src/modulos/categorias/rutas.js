
const controlador = require("./controlador")(require("../../DB/mysql"));
const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");
const { verificarToken, permitirRoles } = require("../auth/middleware");

router.get("/",verificarToken, permitirRoles("administrador","bodegero"), todos);
router.get("/:id",verificarToken, permitirRoles("administrador","bodegero"), uno);
router.post("/",verificarToken, permitirRoles("administrador","bodegero"), agregar);
router.put("/",verificarToken, permitirRoles("administrador","bodegero"), eliminar);

async function todos(req, res, next) {
  try {
    const items = await controlador.todos();
    respuesta.success(req, res, items, 200);
  } catch (error) {
    next(error);
  }
}

async function uno(req, res, next) {
  try {
    const items = await controlador.uno(req.params.id);
    respuesta.success(req, res, items, 200);
  } catch (error) {
    next(error);
  }
}

async function agregar(req, res, next) {
  try {
    const items = await controlador.agregar(req.body);
    if (req.body.id == 0) {
      mensaje = "Item agregado satisfactoriamente";
    } else {
      mensaje = "Item actualizado satisfactoriamente";
    }
    respuesta.success(req, res, mensaje, 201);
  } catch (error) {
    next(error);
  }
}

async function eliminar(req, res, next) {
  try {
    const items = await controlador.eliminar(req.body);
    respuesta.success(req, res, "Item eliminado satisfactoriamente", 200);
  } catch (error) {
    next(error);
  }
}

module.exports = router;
