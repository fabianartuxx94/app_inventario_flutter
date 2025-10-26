const controlador = require("./controlador")(require("../../DB/mysql"));
const express = require("express");
const router = express.Router();
const respuesta = require("../../red/respuestas");


router.post("/login", login);

async function login(req, res, next) {
  try {
    const { username, password } = req.body;
    const data = await controlador.login(username, password);
    respuesta.success(req, res, data, 200);
  } catch (error) {
    respuesta.error(req, res, error.message, 401);
  }
}

module.exports = router;
