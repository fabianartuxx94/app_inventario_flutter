-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 25-10-2025 a las 22:07:46
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `inventario_bodega`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_geocodificar_sitio_venta` (IN `p_sitio_venta_id` INT)   BEGIN
    DECLARE v_direccion_completa TEXT;
    DECLARE v_direccion_hash VARCHAR(64);
    DECLARE v_latitud DECIMAL(10, 8);
    DECLARE v_longitud DECIMAL(11, 8);
    DECLARE v_precision ENUM('exacta', 'aproximada', 'ciudad', 'sin_precision');
    DECLARE v_cache_count INT DEFAULT 0;
    
    -- Obtener dirección completa
    SELECT CONCAT(
        COALESCE(direccion, ''), 
        ', ', 
        COALESCE(barrio, ''), 
        ', ', 
        ciudad
    ) 
    INTO v_direccion_completa 
    FROM sitios_venta 
    WHERE id = p_sitio_venta_id;
    
    -- Verificar si se obtuvo la dirección
    IF v_direccion_completa IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sitio de venta no encontrado';
    END IF;
    
    -- Calcular hash de la dirección
    SET v_direccion_hash = SHA2(v_direccion_completa, 256);
    
    -- Verificar si ya existe en cache
    SELECT COUNT(*), latitud, longitud, precision_obtenida 
    INTO v_cache_count, v_latitud, v_longitud, v_precision
    FROM geocoding_cache 
    WHERE direccion_hash = v_direccion_hash;
    
    IF v_cache_count > 0 THEN
        -- Actualizar con datos del cache
        UPDATE sitios_venta 
        SET latitud = v_latitud,
            longitud = v_longitud,
            precision_geocoding = v_precision,
            geocoding_completo = TRUE,
            ultima_actualizacion = NOW()
        WHERE id = p_sitio_venta_id;
        
        SELECT 'OK' as status, 'Coordenadas actualizadas desde cache' as mensaje;
    ELSE
        -- Marcar que necesita geocoding externo
        UPDATE sitios_venta 
        SET geocoding_completo = FALSE,
            precision_geocoding = 'sin_precision',
            ultima_actualizacion = NOW()
        WHERE id = p_sitio_venta_id;
        
        SELECT 'PENDING' as status, 'Dirección necesita geocoding con Mapbox API' as mensaje;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_guardar_geocoding_mapbox` (IN `p_sitio_venta_id` INT, IN `p_latitud` DECIMAL(10,8), IN `p_longitud` DECIMAL(11,8), IN `p_precision` ENUM('exacta','aproximada','ciudad','sin_precision'), IN `p_respuesta_json` JSON)   BEGIN
    DECLARE v_direccion_completa TEXT;
    DECLARE v_direccion_hash VARCHAR(64);
    
    -- Obtener dirección completa
    SELECT CONCAT(
        COALESCE(direccion, ''), 
        ', ', 
        COALESCE(barrio, ''), 
        ', ', 
        ciudad
    ) 
    INTO v_direccion_completa 
    FROM sitios_venta 
    WHERE id = p_sitio_venta_id;
    
    -- Calcular hash
    SET v_direccion_hash = SHA2(v_direccion_completa, 256);
    
    -- Guardar en cache
    INSERT INTO geocoding_cache (
        direccion_hash,
        direccion_completa,
        latitud,
        longitud,
        precision_obtenida,
        respuesta_json
    ) VALUES (
        v_direccion_hash,
        v_direccion_completa,
        p_latitud,
        p_longitud,
        p_precision,
        p_respuesta_json
    ) ON DUPLICATE KEY UPDATE
        latitud = VALUES(latitud),
        longitud = VALUES(longitud),
        precision_obtenida = VALUES(precision_obtenida),
        respuesta_json = VALUES(respuesta_json),
        actualizado_en = NOW();
    
    -- Actualizar sitio de venta
    UPDATE sitios_venta 
    SET latitud = p_latitud,
        longitud = p_longitud,
        precision_geocoding = p_precision,
        geocoding_completo = TRUE,
        ultima_actualizacion = NOW()
    WHERE id = p_sitio_venta_id;
    
    SELECT 'OK' as status, 'Coordenadas guardadas exitosamente' as mensaje;
    
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `actas`
--

CREATE TABLE `actas` (
  `id` int(11) NOT NULL,
  `tipo` enum('ASIGNACION','TRANSFERENCIA','DEVOLUCION','BAJA','AJUSTE') DEFAULT NULL,
  `descripcion` text DEFAULT NULL,
  `fecha` datetime DEFAULT current_timestamp(),
  `archivo_pdf` text DEFAULT NULL,
  `usuario_creador_id` int(11) NOT NULL,
  `entregado_por_id` int(11) NOT NULL,
  `recibido_por_id` int(11) NOT NULL,
  `auditor_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `actas`
--

INSERT INTO `actas` (`id`, `tipo`, `descripcion`, `fecha`, `archivo_pdf`, `usuario_creador_id`, `entregado_por_id`, `recibido_por_id`, `auditor_id`) VALUES
(3, 'ASIGNACION', 'Entrega de activos a Coordinador TIC', '2025-10-21 16:12:00', NULL, 1, 1, 3, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `acta_detalles`
--

CREATE TABLE `acta_detalles` (
  `id` int(11) NOT NULL,
  `acta_id` int(11) NOT NULL,
  `inventario_id` int(11) NOT NULL,
  `estado_en_acta` enum('Nuevo','Reparado','Dañado','Baja') DEFAULT NULL,
  `comentarios` text DEFAULT NULL,
  `cantidad` int(11) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `articulos`
--

CREATE TABLE `articulos` (
  `id` int(11) NOT NULL,
  `categoria_id` int(11) NOT NULL,
  `marca_id` int(11) DEFAULT NULL,
  `tipo_bodega` enum('BMD','Sistemas') NOT NULL DEFAULT 'Sistemas',
  `es_activo` tinyint(1) DEFAULT 1,
  `tipo_articulo` enum('Activo Fijo','Activo de Control','Consumible') DEFAULT NULL,
  `referencia` varchar(150) NOT NULL,
  `descripcion` text DEFAULT NULL,
  `imagen_path` varchar(255) DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `articulos`
--

INSERT INTO `articulos` (`id`, `categoria_id`, `marca_id`, `tipo_bodega`, `es_activo`, `tipo_articulo`, `referencia`, `descripcion`, `imagen_path`, `creado_en`) VALUES
(1, 2, 3, 'Sistemas', 1, 'Activo Fijo', 'ThinkPad T14 Gen2', NULL, NULL, '2025-10-18 16:48:07'),
(2, 2, 1, 'Sistemas', 1, 'Activo Fijo', 'Latitude 5420', NULL, NULL, '2025-10-18 16:48:07'),
(3, 1, 4, 'BMD', 1, 'Activo Fijo', 'HP EliteDesk 800', NULL, NULL, '2025-10-18 16:48:07'),
(4, 3, 2, 'Sistemas', 1, 'Activo Fijo', 'Monitor 24\" HP', NULL, NULL, '2025-10-18 16:48:07'),
(5, 4, 15, 'Sistemas', 1, 'Activo Fijo', 'Epson L3150', NULL, NULL, '2025-10-18 16:48:07'),
(6, 5, 7, 'Sistemas', 1, 'Activo Fijo', 'Cisco ISR 1100', NULL, NULL, '2025-10-18 16:48:07'),
(7, 6, 11, 'Sistemas', 1, 'Activo de Control', 'Netgear GS108', NULL, '/uploads/images/articulos/switches_netgear_netgear_gs108.jpg', '2025-10-18 16:48:07'),
(8, 7, 13, 'BMD', 1, 'Activo de Control', 'Radio Motorola DM1400', NULL, NULL, '2025-10-18 16:48:07'),
(9, 8, 17, 'Sistemas', 0, 'Consumible', 'Cable UTP Cat6 1m', NULL, '/uploads/images/articulos/cables_y_conectores_logitech_cable_utp_cat6_1m.jpg', '2025-10-18 16:48:07'),
(10, 12, 15, 'Sistemas', 1, 'Consumible', 'Toner Epson T664', NULL, '/uploads/images/articulos/cartuchos_y_toner_epson_toner_epson_t664.jpg', '2025-10-18 16:48:07'),
(11, 10, 19, 'Sistemas', 1, 'Consumible', 'Seagate 1TB HDD', NULL, '/uploads/images/articulos/discos_y_almacenamiento_seagate_seagate_1tb_hdd.jpg', '2025-10-18 16:48:07'),
(12, 11, 17, 'Sistemas', 1, 'Activo de Control', 'Teclado Logitech K120', NULL, '/uploads/images/articulos/teclados_y_ratones_logitech_teclado_logitech_k120.jpg', '2025-10-18 16:48:07'),
(13, 14, 16, 'Sistemas', 1, 'Activo de Control', 'Cámara IP Hikvision', NULL, '/uploads/images/articulos/camaras_y_video_brother_camara_ip_hikvision.jpg', '2025-10-18 16:48:07'),
(15, 9, 12, 'BMD', 1, 'Activo de Control', 'UPS Huawei 1kVA', NULL, '/uploads/images/articulos/baterias_y_ups_huawei_ups_huawei_1kva.jpg', '2025-10-18 16:48:07'),
(16, 13, 5, 'Sistemas', 0, 'Consumible', 'Funda y cargador móvil', 'protector para el celular', '/uploads/images/articulos/accesorios_moviles_asus_funda_y_cargador_movil.jpg', '2025-10-18 16:48:07'),
(20, 20, 18, 'Sistemas', 1, 'Activo Fijo', 'Fuente de poder ATX', 'fuente atx de 750 w', '/uploads/images/articulos/componentes_internos_kingston_fuente_de_poder_atx.jpg', '2025-10-18 16:48:07'),
(21, 11, 28, 'Sistemas', 1, 'Activo de Control', 'KB-100X', 'Teclado alambrico marca genius latino', NULL, '2025-10-23 15:03:54');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asignaciones`
--

CREATE TABLE `asignaciones` (
  `id` int(11) NOT NULL,
  `inventario_id` int(11) NOT NULL,
  `tecnico_id` int(11) NOT NULL,
  `sitio_venta_id` int(11) NOT NULL,
  `fecha_asignacion` datetime DEFAULT current_timestamp(),
  `usuario_asignador_id` int(11) NOT NULL,
  `estado` enum('asignado','instalado','devuelto','pendiente') DEFAULT 'asignado',
  `observaciones` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `asignaciones`
--
DELIMITER $$
CREATE TRIGGER `trg_asignacion_insert` AFTER INSERT ON `asignaciones` FOR EACH ROW BEGIN
  -- Actualizar estado del inventario
  UPDATE inventario 
  SET estado_asignacion = 'asignado',
      fecha_actualizacion = NOW()
  WHERE id = NEW.inventario_id;
  
  -- Registrar en historial
  INSERT INTO historial_inventario (
    inventario_id,
    accion,
    datos_nuevos,
    usuario_id,
    fecha_cambio,
    asignacion_id
  ) VALUES (
    NEW.inventario_id,
    'ASIGNACION',
    JSON_OBJECT(
      'tecnico_id', NEW.tecnico_id,
      'sitio_venta_id', NEW.sitio_venta_id,
      'estado_asignacion', 'asignado',
      'observaciones', NEW.observaciones
    ),
    NEW.usuario_asignador_id,
    NOW(),
    NEW.id
  );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categorias`
--

CREATE TABLE `categorias` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `categorias`
--

INSERT INTO `categorias` (`id`, `nombre`, `creado_en`) VALUES
(1, 'Computadores de escritorio', '2025-10-18 16:48:07'),
(2, 'Portátiles', '2025-10-18 16:48:07'),
(3, 'Monitores', '2025-10-18 16:48:07'),
(4, 'Impresoras', '2025-10-18 16:48:07'),
(5, 'Routers', '2025-10-18 16:48:07'),
(6, 'Switches', '2025-10-18 16:48:07'),
(7, 'Antenas y radios', '2025-10-18 16:48:07'),
(8, 'Cables y conectores', '2025-10-18 16:48:07'),
(9, 'Baterías y UPS', '2025-10-18 16:48:07'),
(10, 'Discos y almacenamiento', '2025-10-18 16:48:07'),
(11, 'Teclados', '2025-10-18 16:48:07'),
(12, 'Cartuchos y toner', '2025-10-18 16:48:07'),
(13, 'Accesorios móviles', '2025-10-18 16:48:07'),
(14, 'Cámaras y video', '2025-10-18 16:48:07'),
(15, 'Puntos de acceso', '2025-10-18 16:48:07'),
(16, 'Fuente de poder', '2025-10-18 16:48:07'),
(17, 'Kits de instalación', '2025-10-18 16:48:07'),
(18, 'Etiquetas y consumibles', '2025-10-18 16:48:07'),
(19, 'Sistemas de telefonía', '2025-10-18 16:48:07'),
(20, 'Componentes internos', '2025-10-18 16:48:07'),
(21, 'Regulador de energia', '2025-10-18 19:38:35');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `devoluciones`
--

CREATE TABLE `devoluciones` (
  `id` int(11) NOT NULL,
  `asignacion_id` int(11) NOT NULL,
  `tecnico_id` int(11) NOT NULL,
  `sitio_venta_id` int(11) NOT NULL,
  `fecha_devolucion` datetime DEFAULT current_timestamp(),
  `usuario_receptor_id` int(11) NOT NULL,
  `estado_equipo` enum('bueno','danado','reparacion') DEFAULT 'bueno',
  `motivo_devolucion` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Disparadores `devoluciones`
--
DELIMITER $$
CREATE TRIGGER `trg_devolucion_insert` AFTER INSERT ON `devoluciones` FOR EACH ROW BEGIN
  -- Actualizar estado del inventario y asignación
  UPDATE inventario 
  SET estado_asignacion = 'disponible',
      fecha_actualizacion = NOW()
  WHERE id = (SELECT inventario_id FROM asignaciones WHERE id = NEW.asignacion_id);
  
  UPDATE asignaciones 
  SET estado = 'devuelto'
  WHERE id = NEW.asignacion_id;
  
  -- Registrar en historial
  INSERT INTO historial_inventario (
    inventario_id,
    accion,
    datos_nuevos,
    usuario_id,
    fecha_cambio,
    devolucion_id
  ) VALUES (
    (SELECT inventario_id FROM asignaciones WHERE id = NEW.asignacion_id),
    'DEVOLUCION',
    JSON_OBJECT(
      'tecnico_id', NEW.tecnico_id,
      'sitio_venta_id', NEW.sitio_venta_id,
      'estado_equipo', NEW.estado_equipo,
      'motivo_devolucion', NEW.motivo_devolucion,
      'estado_asignacion', 'disponible'
    ),
    NEW.usuario_receptor_id,
    NOW(),
    NEW.id
  );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `geocoding_cache`
--

CREATE TABLE `geocoding_cache` (
  `id` int(11) NOT NULL,
  `direccion_hash` varchar(64) DEFAULT NULL,
  `direccion_completa` text DEFAULT NULL,
  `latitud` decimal(10,8) DEFAULT NULL,
  `longitud` decimal(11,8) DEFAULT NULL,
  `precision_obtenida` enum('exacta','aproximada','ciudad','sin_precision') DEFAULT NULL,
  `respuesta_json` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`respuesta_json`)),
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historial_inventario`
--

CREATE TABLE `historial_inventario` (
  `id` int(11) NOT NULL,
  `inventario_id` int(11) NOT NULL,
  `accion` enum('CREACION','ACTUALIZACION','BAJA') NOT NULL,
  `datos_anteriores` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`datos_anteriores`)),
  `datos_nuevos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`datos_nuevos`)),
  `usuario_id` int(11) NOT NULL,
  `fecha_cambio` datetime DEFAULT current_timestamp(),
  `asignacion_id` int(11) DEFAULT NULL,
  `devolucion_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `historial_inventario`
--

INSERT INTO `historial_inventario` (`id`, `inventario_id`, `accion`, `datos_anteriores`, `datos_nuevos`, `usuario_id`, `fecha_cambio`, `asignacion_id`, `devolucion_id`) VALUES
(1, 3, 'CREACION', NULL, '{\"articulo_id\": 1, \"placa\": \"AF00001\", \"serial\": \"SN12345\", \"estado\": \"Nuevo\", \"cantidad\": 1, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 1\", \"usuario_id\": 1, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-21 16:10:56\"}', 1, '2025-10-21 16:10:56', NULL, NULL),
(2, 4, 'CREACION', NULL, '{\"articulo_id\": 2, \"placa\": \"AF00002\", \"serial\": \"SN54321\", \"estado\": \"Nuevo\", \"cantidad\": 1, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 2\", \"usuario_id\": 1, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-21 16:10:56\"}', 1, '2025-10-21 16:10:56', NULL, NULL),
(3, 5, 'CREACION', NULL, '{\"articulo_id\": 3, \"placa\": null, \"serial\": null, \"estado\": \"Nuevo\", \"cantidad\": 20, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 3\", \"usuario_id\": 22, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-21 16:10:56\"}', 22, '2025-10-21 16:10:56', NULL, NULL),
(4, 6, 'CREACION', NULL, '{\"articulo_id\": 4, \"placa\": null, \"serial\": null, \"estado\": \"Nuevo\", \"cantidad\": 15, \"bodega\": \"Bodega Garzon\", \"ubicacion_detallada\": \"Estante 1\", \"usuario_id\": 22, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-21 16:10:56\"}', 22, '2025-10-21 16:10:56', NULL, NULL),
(5, 3, 'ACTUALIZACION', '{\"articulo_id\": 1, \"placa\": \"AF00001\", \"serial\": \"SN12345\", \"estado\": \"Nuevo\", \"cantidad\": 1, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 1\", \"usuario_id\": 1, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-21 16:10:56\"}', '{\"articulo_id\": 1, \"placa\": \"AF00001\", \"serial\": \"SN12345\", \"estado\": \"Nuevo\", \"cantidad\": 1, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 2\", \"usuario_id\": 1, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-22 13:01:50\"}', 1, '2025-10-22 13:01:50', NULL, NULL),
(6, 5, 'ACTUALIZACION', '{\"articulo_id\": 3, \"placa\": null, \"serial\": null, \"estado\": \"Nuevo\", \"cantidad\": 20, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 3\", \"usuario_id\": 22, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-21 16:10:56\"}', '{\"articulo_id\": 3, \"placa\": null, \"serial\": null, \"estado\": \"Bueno\", \"cantidad\": 20, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 3\", \"usuario_id\": 22, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-22 16:16:45\"}', 22, '2025-10-22 16:16:45', NULL, NULL),
(7, 4, 'ACTUALIZACION', '{\"articulo_id\": 2, \"placa\": \"AF00002\", \"serial\": \"SN54321\", \"estado\": \"Nuevo\", \"cantidad\": 1, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 2\", \"usuario_id\": 1, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-21 16:10:56\"}', '{\"articulo_id\": 2, \"placa\": \"AF00002\", \"serial\": \"SN54321\", \"estado\": \"Reparacion\", \"cantidad\": 1, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 2\", \"usuario_id\": 1, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-22 16:16:50\"}', 1, '2025-10-22 16:16:50', NULL, NULL),
(8, 4, 'ACTUALIZACION', '{\"articulo_id\": 2, \"placa\": \"AF00002\", \"serial\": \"SN54321\", \"estado\": \"Reparacion\", \"cantidad\": 1, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 2\", \"usuario_id\": 1, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-22 16:16:50\"}', '{\"articulo_id\": 11, \"placa\": \"AF00002\", \"serial\": \"SN54321\", \"estado\": \"Reparacion\", \"cantidad\": 1, \"bodega\": \"Bodega Principal\", \"ubicacion_detallada\": \"Estante 2\", \"usuario_id\": 1, \"fecha_creacion\": \"2025-10-21 16:10:56\", \"fecha_actualizacion\": \"2025-10-22 16:39:10\"}', 1, '2025-10-22 16:39:10', NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `inventario`
--

CREATE TABLE `inventario` (
  `id` int(11) NOT NULL,
  `articulo_id` int(11) NOT NULL,
  `placa` varchar(100) DEFAULT NULL,
  `serial` varchar(100) DEFAULT NULL,
  `estado` enum('Nuevo','Bueno','Reparacion','Baja') NOT NULL,
  `estado_asignacion` enum('disponible','asignado','instalado','en_mantenimiento') DEFAULT 'disponible',
  `cantidad` int(11) NOT NULL DEFAULT 1,
  `bodega` enum('Bodega Principal','Bodega Garzón','Bodega Pitalito') NOT NULL,
  `ubicacion_detallada` varchar(255) DEFAULT NULL,
  `usuario_id` int(11) NOT NULL,
  `fecha_creacion` datetime DEFAULT current_timestamp(),
  `fecha_actualizacion` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `inventario`
--

INSERT INTO `inventario` (`id`, `articulo_id`, `placa`, `serial`, `estado`, `estado_asignacion`, `cantidad`, `bodega`, `ubicacion_detallada`, `usuario_id`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(3, 1, 'AF00001', 'SN12345', 'Nuevo', 'disponible', 1, 'Bodega Principal', 'Estante 2', 1, '2025-10-21 16:10:56', '2025-10-22 13:01:50'),
(4, 11, 'AF00002', 'SN54321', 'Reparacion', 'disponible', 1, 'Bodega Principal', 'Estante 2', 1, '2025-10-21 16:10:56', '2025-10-22 16:39:10'),
(5, 3, NULL, NULL, 'Bueno', 'disponible', 20, 'Bodega Principal', 'Estante 3', 22, '2025-10-21 16:10:56', '2025-10-22 16:16:45'),
(6, 4, NULL, NULL, 'Nuevo', 'disponible', 15, 'Bodega Garzón', 'Estante 1', 22, '2025-10-21 16:10:56', '2025-10-21 16:10:56');

--
-- Disparadores `inventario`
--
DELIMITER $$
CREATE TRIGGER `trg_inventario_delete` AFTER DELETE ON `inventario` FOR EACH ROW BEGIN
  INSERT INTO historial_inventario (
    inventario_id,
    accion,
    datos_anteriores,
    usuario_id,
    fecha_cambio
  ) VALUES (
    OLD.id,
    'BAJA',
    JSON_OBJECT(
      'articulo_id', OLD.articulo_id,
      'placa', OLD.placa,
      'serial', OLD.serial,
      'estado', OLD.estado,
      'cantidad', OLD.cantidad,
      'bodega', OLD.bodega,
      'ubicacion_detallada', OLD.ubicacion_detallada,
      'usuario_id', OLD.usuario_id,
      'fecha_creacion', OLD.fecha_creacion,
      'fecha_actualizacion', OLD.fecha_actualizacion
    ),
    OLD.usuario_id,
    NOW()
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_inventario_insert` AFTER INSERT ON `inventario` FOR EACH ROW BEGIN
  DECLARE v_tipo_articulo VARCHAR(50);
  SELECT tipo_articulo INTO v_tipo_articulo FROM articulos WHERE id = NEW.articulo_id;
  
  -- Registrar en historial (con estado_asignacion)
  INSERT INTO historial_inventario (
    inventario_id,
    accion,
    datos_nuevos,
    usuario_id,
    fecha_cambio
  ) VALUES (
    NEW.id,
    'CREACION',
    JSON_OBJECT(
      'articulo_id', NEW.articulo_id,
      'placa', NEW.placa,
      'serial', NEW.serial,
      'estado', NEW.estado,
      'estado_asignacion', NEW.estado_asignacion,
      'cantidad', NEW.cantidad,
      'bodega', NEW.bodega,
      'ubicacion_detallada', NEW.ubicacion_detallada,
      'usuario_id', NEW.usuario_id,
      'fecha_creacion', NEW.fecha_creacion,
      'fecha_actualizacion', NEW.fecha_actualizacion
    ),
    NEW.usuario_id,
    NOW()
  );
  
  -- Lógica stock_bodegas (existente)
  INSERT INTO stock_bodegas (articulo_id, bodega, tipo_articulo, stock_actual, activos_disponibles)
  VALUES (
    NEW.articulo_id, 
    NEW.bodega, 
    v_tipo_articulo,
    CASE WHEN v_tipo_articulo = 'Consumible' THEN NEW.cantidad ELSE 0 END,
    CASE WHEN v_tipo_articulo IN ('Activo Fijo', 'Activo de Control') THEN NEW.cantidad ELSE 0 END
  )
  ON DUPLICATE KEY UPDATE 
    stock_actual = CASE 
      WHEN v_tipo_articulo = 'Consumible' THEN stock_actual + NEW.cantidad 
      ELSE stock_actual 
    END,
    activos_disponibles = CASE 
      WHEN v_tipo_articulo IN ('Activo Fijo', 'Activo de Control') THEN activos_disponibles + NEW.cantidad 
      ELSE activos_disponibles 
    END,
    actualizado_en = NOW();
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_inventario_insert_stock` AFTER INSERT ON `inventario` FOR EACH ROW BEGIN
    DECLARE v_tipo_articulo VARCHAR(50);
    
    -- Obtener tipo de artículo
    SELECT tipo_articulo INTO v_tipo_articulo 
    FROM articulos WHERE id = NEW.articulo_id;
    
    INSERT INTO stock_bodegas (articulo_id, bodega, tipo_articulo, stock_actual, activos_disponibles)
    VALUES (
        NEW.articulo_id, 
        NEW.bodega, 
        v_tipo_articulo,
        -- ✅ CONSUMIBLES: suma cantidad
        CASE WHEN v_tipo_articulo = 'Consumible' THEN NEW.cantidad ELSE 0 END,
        -- ✅ ACTIVOS: cuenta unidades (siempre cantidad = 1)
        CASE WHEN v_tipo_articulo IN ('Activo Fijo', 'Activo de Control') THEN NEW.cantidad ELSE 0 END
    )
    ON DUPLICATE KEY UPDATE 
        stock_actual = CASE 
            WHEN v_tipo_articulo = 'Consumible' THEN stock_actual + NEW.cantidad 
            ELSE stock_actual 
        END,
        activos_disponibles = CASE 
            WHEN v_tipo_articulo IN ('Activo Fijo', 'Activo de Control') THEN activos_disponibles + NEW.cantidad 
            ELSE activos_disponibles 
        END,
        actualizado_en = NOW();
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_inventario_update` AFTER UPDATE ON `inventario` FOR EACH ROW BEGIN
  INSERT INTO historial_inventario (
    inventario_id,
    accion,
    datos_anteriores,
    datos_nuevos,
    usuario_id,
    fecha_cambio
  ) VALUES (
    OLD.id,
    'ACTUALIZACION',
    JSON_OBJECT(
      'articulo_id', OLD.articulo_id,
      'placa', OLD.placa,
      'serial', OLD.serial,
      'estado', OLD.estado,
      'cantidad', OLD.cantidad,
      'bodega', OLD.bodega,
      'ubicacion_detallada', OLD.ubicacion_detallada,
      'usuario_id', OLD.usuario_id,
      'fecha_creacion', OLD.fecha_creacion,
      'fecha_actualizacion', OLD.fecha_actualizacion
    ),
    JSON_OBJECT(
      'articulo_id', NEW.articulo_id,
      'placa', NEW.placa,
      'serial', NEW.serial,
      'estado', NEW.estado,
      'cantidad', NEW.cantidad,
      'bodega', NEW.bodega,
      'ubicacion_detallada', NEW.ubicacion_detallada,
      'usuario_id', NEW.usuario_id,
      'fecha_creacion', NEW.fecha_creacion,
      'fecha_actualizacion', NEW.fecha_actualizacion
    ),
    NEW.usuario_id,
    NOW()
  );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_inventario_update_stock` AFTER UPDATE ON `inventario` FOR EACH ROW BEGIN
    DECLARE v_tipo_articulo VARCHAR(50);
    DECLARE v_diferencia INT;
    
    -- Obtener tipo de artículo
    SELECT tipo_articulo INTO v_tipo_articulo 
    FROM articulos WHERE id = NEW.articulo_id;
    
    -- Calcular diferencia (para cambios de bodega o cantidad)
    IF OLD.bodega != NEW.bodega OR OLD.cantidad != NEW.cantidad THEN
        -- Restar del stock anterior
        UPDATE stock_bodegas 
        SET stock_actual = CASE 
                WHEN v_tipo_articulo = 'Consumible' THEN stock_actual - OLD.cantidad 
                ELSE stock_actual 
            END,
            activos_disponibles = CASE 
                WHEN v_tipo_articulo IN ('Activo Fijo', 'Activo de Control') THEN activos_disponibles - OLD.cantidad 
                ELSE activos_disponibles 
            END,
            actualizado_en = NOW()
        WHERE articulo_id = OLD.articulo_id AND bodega = OLD.bodega;
        
        -- Sumar al nuevo stock
        INSERT INTO stock_bodegas (articulo_id, bodega, tipo_articulo, stock_actual, activos_disponibles)
        VALUES (
            NEW.articulo_id, 
            NEW.bodega, 
            v_tipo_articulo,
            CASE WHEN v_tipo_articulo = 'Consumible' THEN NEW.cantidad ELSE 0 END,
            CASE WHEN v_tipo_articulo IN ('Activo Fijo', 'Activo de Control') THEN NEW.cantidad ELSE 0 END
        )
        ON DUPLICATE KEY UPDATE 
            stock_actual = CASE 
                WHEN v_tipo_articulo = 'Consumible' THEN stock_actual + NEW.cantidad 
                ELSE stock_actual 
            END,
            activos_disponibles = CASE 
                WHEN v_tipo_articulo IN ('Activo Fijo', 'Activo de Control') THEN activos_disponibles + NEW.cantidad 
                ELSE activos_disponibles 
            END,
            actualizado_en = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `marcas`
--

CREATE TABLE `marcas` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `marcas`
--

INSERT INTO `marcas` (`id`, `nombre`) VALUES
(4, 'Acer'),
(23, 'Adata'),
(6, 'Apple'),
(5, 'Asus'),
(16, 'Brother'),
(7, 'Cisco'),
(1, 'Dell'),
(15, 'Epson'),
(28, 'Genius'),
(2, 'HP'),
(12, 'Huawei'),
(22, 'Janus'),
(18, 'Kingston'),
(26, 'Kioxia'),
(3, 'Lenovo'),
(17, 'Logitech'),
(10, 'MikroTik'),
(13, 'Motorola'),
(11, 'Netgear'),
(24, 'Powest'),
(21, 'Samsung'),
(19, 'Seagate'),
(9, 'TP-Link'),
(8, 'Ubiquiti'),
(20, 'Western Digital'),
(27, 'Xiaomi'),
(14, 'Zebra');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `notificaciones`
--

CREATE TABLE `notificaciones` (
  `id` int(11) NOT NULL,
  `usuario_id` int(11) NOT NULL,
  `titulo` varchar(255) NOT NULL,
  `mensaje` text NOT NULL,
  `tipo` enum('transferencia','asignacion','devolucion','sistema') DEFAULT 'sistema',
  `leida` tinyint(1) DEFAULT 0,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  `leido_en` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personal`
--

CREATE TABLE `personal` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `identificacion` varchar(50) NOT NULL,
  `cargo` varchar(100) NOT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `tipo` enum('tecnico','auditor','coordinador','bodega','admin','usuario') DEFAULT 'usuario',
  `email` varchar(100) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp(),
  `fecha_actualizacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `personal`
--

INSERT INTO `personal` (`id`, `nombre`, `identificacion`, `cargo`, `activo`, `tipo`, `email`, `telefono`, `fecha_creacion`, `fecha_actualizacion`) VALUES
(1, 'Fabian Artunduaga Fajardo', '1078778021', 'Técnico de Sistemas', 1, 'tecnico', 'fabian.artunduaga@suchance.com', NULL, '2025-10-25 16:01:43', '2025-10-25 17:20:55'),
(2, 'Fabian Andres Covilla Murcia', '1078777989', 'Técnico de Sistemas', 1, 'tecnico', NULL, NULL, '2025-10-25 16:01:43', '2025-10-25 18:39:38'),
(3, 'Luis Torres', '11223344', 'Coordinador TIC', 1, 'usuario', NULL, NULL, '2025-10-25 16:01:43', '2025-10-25 16:01:43');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sitios_venta`
--

CREATE TABLE `sitios_venta` (
  `id` int(11) NOT NULL,
  `zona` int(11) NOT NULL,
  `centro_costos` int(11) NOT NULL,
  `tipo_sv` enum('PUNTO FIJO','TIENDA A TIENDA','MODULO') NOT NULL,
  `codigo_sv` varchar(20) NOT NULL,
  `sitio_venta` varchar(255) NOT NULL,
  `direccion` text DEFAULT NULL,
  `ciudad` varchar(100) NOT NULL,
  `barrio` varchar(150) DEFAULT NULL,
  `latitud` decimal(10,8) DEFAULT NULL,
  `longitud` decimal(11,8) DEFAULT NULL,
  `geocoding_completo` tinyint(1) DEFAULT 0,
  `precision_geocoding` enum('exacta','aproximada','ciudad','sin_precision') DEFAULT 'sin_precision',
  `estado_sv` enum('Activo','Inactivo','Mantenimiento') DEFAULT 'Activo',
  `tecnologias_sv` varchar(100) DEFAULT NULL,
  `ultima_actualizacion` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `sincronizado_movil` tinyint(1) DEFAULT 0,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `sitios_venta`
--

INSERT INTO `sitios_venta` (`id`, `zona`, `centro_costos`, `tipo_sv`, `codigo_sv`, `sitio_venta`, `direccion`, `ciudad`, `barrio`, `latitud`, `longitud`, `geocoding_completo`, `precision_geocoding`, `estado_sv`, `tecnologias_sv`, `ultima_actualizacion`, `sincronizado_movil`, `creado_en`) VALUES
(1, 2, 24, 'PUNTO FIJO', '24001', 'ACEVEDO OFICINA PRINCIPAL', 'CENTROCARRERA 5 No 7 - 35 CENTRO', 'ACEVEDO', 'CENTRO ACEVEDO', 1.80711900, -75.89087400, 1, 'exacta', 'Activo', 'NEWPOS-ANDROID-PC', '2025-10-24 21:26:36', 0, '2025-10-23 13:55:00'),
(2, 2, 24, 'TIENDA A TIENDA', '24011', 'AUTOMOTOS PLUS', 'CRA 5 # 2-40', 'ACEVEDO', 'CENTRO ACEVEDO', 1.80737800, -75.88845000, 1, 'aproximada', 'Activo', 'PC', '2025-10-24 23:59:46', 0, '2025-10-23 13:55:00'),
(3, 2, 24, 'PUNTO FIJO', '24003', 'CRUCE FLORENCIA', 'CENTRO POBLADO CRUCE FLORENCIA', 'ACEVEDO', 'CENTRO ACEVEDO', 1.87526800, -75.82553700, 1, 'ciudad', 'Activo', 'PC', '2025-10-24 23:59:37', 0, '2025-10-23 13:55:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `stock_bodegas`
--

CREATE TABLE `stock_bodegas` (
  `id` int(11) NOT NULL,
  `articulo_id` int(11) NOT NULL,
  `bodega` enum('Bodega Principal','Bodega Garzón','Bodega Pitalito') NOT NULL,
  `tipo_articulo` enum('Activo Fijo','Activo de Control','Consumible') NOT NULL,
  `stock_actual` int(11) NOT NULL DEFAULT 0,
  `stock_minimo` int(11) NOT NULL DEFAULT 0,
  `activos_disponibles` int(11) NOT NULL DEFAULT 0,
  `ubicacion_detallada` varchar(255) DEFAULT NULL,
  `creado_en` timestamp NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `transferencias_bodegas`
--

CREATE TABLE `transferencias_bodegas` (
  `id` int(11) NOT NULL,
  `acta_id` int(11) DEFAULT NULL,
  `inventario_id` int(11) NOT NULL,
  `bodega_origen` varchar(100) NOT NULL,
  `bodega_destino` varchar(100) NOT NULL,
  `cantidad` int(11) NOT NULL DEFAULT 1,
  `usuario_solicitante_id` int(11) NOT NULL,
  `usuario_aprobador_id` int(11) DEFAULT NULL,
  `estado` enum('pendiente','aprobada','rechazada','completada') DEFAULT 'pendiente',
  `motivo` text DEFAULT NULL,
  `fecha_solicitud` datetime DEFAULT current_timestamp(),
  `fecha_aprobacion` datetime DEFAULT NULL,
  `fecha_completacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `nombre_completo` varchar(150) DEFAULT NULL,
  `rol` enum('administrador','tecnico','bodega','usuario') DEFAULT 'usuario',
  `bodega` enum('Bodega Principal','Bodega Garzón','Bodega Pitalito') DEFAULT NULL,
  `activo` tinyint(1) DEFAULT 1,
  `fecha_creacion` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`id`, `username`, `password_hash`, `nombre_completo`, `rol`, `bodega`, `activo`, `fecha_creacion`) VALUES
(1, 'admin', '$2b$10$imv0rlN9wA8QqawSutZQVOnVXrZjGYKgFO0dqMh2PDyiR.MHPcaIO', 'Administrador Principal', 'administrador', 'Bodega Principal', 1, '2025-09-18 08:28:56'),
(22, 'Tecnico01', '$2b$10$S57x9R34IuzHMCA4o2H2RerLTRe9kaseqiflzOkcytVu/79qgn0UW', 'FabianArtunduaga Fajardo', 'tecnico', 'Bodega Principal', 1, '2025-10-21 13:14:19'),
(23, 'Bodegaadmin', '$2b$10$nEoYmKG8lmeeSUTEZmA.Qu3gAT74r7uJZhJsE/AcrQyxq4ROF8dWW', 'Jeferson Danilo Quintero', 'bodega', 'Bodega Principal', 1, '2025-10-21 13:15:09');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_asignaciones_tecnicos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_asignaciones_tecnicos` (
`asignacion_id` int(11)
,`tecnico_id` int(11)
,`tecnico_nombre` varchar(100)
,`inventario_id` int(11)
,`placa` varchar(100)
,`serial` varchar(100)
,`articulo_referencia` varchar(150)
,`sitio_venta_id` int(11)
,`sitio_venta` varchar(255)
,`direccion` text
,`latitud` decimal(10,8)
,`longitud` decimal(11,8)
,`ciudad` varchar(100)
,`estado_asignacion` enum('asignado','instalado','devuelto','pendiente')
,`fecha_asignacion` datetime
,`observaciones` text
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_dashboard_stock`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_dashboard_stock` (
`categoria_nombre` varchar(100)
,`total_referencias` bigint(21)
,`consumibles_totales` decimal(54,0)
,`consumibles_minimo` decimal(54,0)
,`activos_totales` decimal(54,0)
,`referencias_con_alerta` bigint(21)
,`porcentaje_cobertura` decimal(60,2)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_sitios_venta_mapa`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_sitios_venta_mapa` (
`id` int(11)
,`codigo_sv` varchar(20)
,`sitio_venta` varchar(255)
,`direccion` text
,`ciudad` varchar(100)
,`barrio` varchar(150)
,`latitud` decimal(10,8)
,`longitud` decimal(11,8)
,`tipo_sv` enum('PUNTO FIJO','TIENDA A TIENDA','MODULO')
,`estado_sv` enum('Activo','Inactivo','Mantenimiento')
,`tecnologias_sv` varchar(100)
,`mapbox_icon` varchar(9)
,`mapbox_color` varchar(6)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_stock_contrastado`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_stock_contrastado` (
`articulo_id` int(11)
,`referencia` varchar(150)
,`descripcion` text
,`tipo_articulo` enum('Activo Fijo','Activo de Control','Consumible')
,`categoria_nombre` varchar(100)
,`marca_nombre` varchar(50)
,`consumibles_principal` bigint(11)
,`activos_principal` bigint(11)
,`consumibles_garzon` bigint(11)
,`activos_garzon` bigint(11)
,`consumibles_pitalito` bigint(11)
,`activos_pitalito` bigint(11)
,`stock_min_principal` bigint(11)
,`stock_min_garzon` bigint(11)
,`stock_min_pitalito` bigint(11)
,`stock_total` decimal(32,0)
,`stock_minimo_promedio` decimal(14,4)
,`estado_stock` varchar(17)
,`total_consumibles` decimal(32,0)
,`total_activos` decimal(32,0)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_stock_jerarquico`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_stock_jerarquico` (
`categoria_nombre` varchar(100)
,`marca_nombre` varchar(50)
,`referencia` varchar(150)
,`descripcion` text
,`tipo_articulo` enum('Activo Fijo','Activo de Control','Consumible')
,`total_referencias` bigint(21)
,`total_consumibles` decimal(32,0)
,`total_minimo_consumibles` decimal(32,0)
,`total_activos` decimal(32,0)
,`alerta_categoria` varchar(20)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_asignaciones_tecnicos`
--
DROP TABLE IF EXISTS `vista_asignaciones_tecnicos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_asignaciones_tecnicos`  AS SELECT `a`.`id` AS `asignacion_id`, `a`.`tecnico_id` AS `tecnico_id`, `p`.`nombre` AS `tecnico_nombre`, `a`.`inventario_id` AS `inventario_id`, `i`.`placa` AS `placa`, `i`.`serial` AS `serial`, `ar`.`referencia` AS `articulo_referencia`, `a`.`sitio_venta_id` AS `sitio_venta_id`, `sv`.`sitio_venta` AS `sitio_venta`, `sv`.`direccion` AS `direccion`, `sv`.`latitud` AS `latitud`, `sv`.`longitud` AS `longitud`, `sv`.`ciudad` AS `ciudad`, `a`.`estado` AS `estado_asignacion`, `a`.`fecha_asignacion` AS `fecha_asignacion`, `a`.`observaciones` AS `observaciones` FROM ((((`asignaciones` `a` join `personal` `p` on(`a`.`tecnico_id` = `p`.`id` and `p`.`tipo` = 'tecnico' and `p`.`activo` = 1)) join `inventario` `i` on(`a`.`inventario_id` = `i`.`id`)) join `articulos` `ar` on(`i`.`articulo_id` = `ar`.`id`)) join `sitios_venta` `sv` on(`a`.`sitio_venta_id` = `sv`.`id`)) WHERE `a`.`estado` in ('asignado','pendiente') AND `sv`.`latitud` is not null AND `sv`.`longitud` is not null ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_dashboard_stock`
--
DROP TABLE IF EXISTS `vista_dashboard_stock`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_dashboard_stock`  AS SELECT `vista_stock_jerarquico`.`categoria_nombre` AS `categoria_nombre`, count(distinct `vista_stock_jerarquico`.`referencia`) AS `total_referencias`, sum(`vista_stock_jerarquico`.`total_consumibles`) AS `consumibles_totales`, sum(`vista_stock_jerarquico`.`total_minimo_consumibles`) AS `consumibles_minimo`, sum(`vista_stock_jerarquico`.`total_activos`) AS `activos_totales`, count(case when `vista_stock_jerarquico`.`alerta_categoria` = 'stock_bajo_categoria' then 1 end) AS `referencias_con_alerta`, CASE WHEN sum(`vista_stock_jerarquico`.`total_minimo_consumibles`) > 0 THEN round(sum(`vista_stock_jerarquico`.`total_consumibles`) / sum(`vista_stock_jerarquico`.`total_minimo_consumibles`) * 100,2) ELSE 100 END AS `porcentaje_cobertura` FROM `vista_stock_jerarquico` GROUP BY `vista_stock_jerarquico`.`categoria_nombre` ORDER BY CASE WHEN sum(`vista_stock_jerarquico`.`total_minimo_consumibles`) > 0 THEN round(sum(`vista_stock_jerarquico`.`total_consumibles`) / sum(`vista_stock_jerarquico`.`total_minimo_consumibles`) * 100,2) ELSE 100 END ASC, count(case when `vista_stock_jerarquico`.`alerta_categoria` = 'stock_bajo_categoria' then 1 end) DESC ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_sitios_venta_mapa`
--
DROP TABLE IF EXISTS `vista_sitios_venta_mapa`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_sitios_venta_mapa`  AS SELECT `sitios_venta`.`id` AS `id`, `sitios_venta`.`codigo_sv` AS `codigo_sv`, `sitios_venta`.`sitio_venta` AS `sitio_venta`, `sitios_venta`.`direccion` AS `direccion`, `sitios_venta`.`ciudad` AS `ciudad`, `sitios_venta`.`barrio` AS `barrio`, `sitios_venta`.`latitud` AS `latitud`, `sitios_venta`.`longitud` AS `longitud`, `sitios_venta`.`tipo_sv` AS `tipo_sv`, `sitios_venta`.`estado_sv` AS `estado_sv`, `sitios_venta`.`tecnologias_sv` AS `tecnologias_sv`, CASE WHEN `sitios_venta`.`tipo_sv` = 'PUNTO FIJO' THEN 'office' WHEN `sitios_venta`.`tipo_sv` = 'TIENDA A TIENDA' THEN 'shop' ELSE 'warehouse' END AS `mapbox_icon`, CASE WHEN `sitios_venta`.`estado_sv` = 'Activo' THEN 'green' WHEN `sitios_venta`.`estado_sv` = 'Mantenimiento' THEN 'orange' ELSE 'red' END AS `mapbox_color` FROM `sitios_venta` WHERE `sitios_venta`.`latitud` is not null AND `sitios_venta`.`longitud` is not null AND `sitios_venta`.`estado_sv` <> 'Inactivo' ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_stock_contrastado`
--
DROP TABLE IF EXISTS `vista_stock_contrastado`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_stock_contrastado`  AS SELECT `a`.`id` AS `articulo_id`, `a`.`referencia` AS `referencia`, `a`.`descripcion` AS `descripcion`, `a`.`tipo_articulo` AS `tipo_articulo`, `c`.`nombre` AS `categoria_nombre`, `m`.`nombre` AS `marca_nombre`, coalesce(max(case when `sb`.`bodega` = 'Bodega Principal' and `a`.`tipo_articulo` = 'Consumible' then `sb`.`stock_actual` end),0) AS `consumibles_principal`, coalesce(max(case when `sb`.`bodega` = 'Bodega Principal' and `a`.`tipo_articulo` in ('Activo Fijo','Activo de Control') then `sb`.`activos_disponibles` end),0) AS `activos_principal`, coalesce(max(case when `sb`.`bodega` = 'Bodega Garzón' and `a`.`tipo_articulo` = 'Consumible' then `sb`.`stock_actual` end),0) AS `consumibles_garzon`, coalesce(max(case when `sb`.`bodega` = 'Bodega Garzón' and `a`.`tipo_articulo` in ('Activo Fijo','Activo de Control') then `sb`.`activos_disponibles` end),0) AS `activos_garzon`, coalesce(max(case when `sb`.`bodega` = 'Bodega Pitalito' and `a`.`tipo_articulo` = 'Consumible' then `sb`.`stock_actual` end),0) AS `consumibles_pitalito`, coalesce(max(case when `sb`.`bodega` = 'Bodega Pitalito' and `a`.`tipo_articulo` in ('Activo Fijo','Activo de Control') then `sb`.`activos_disponibles` end),0) AS `activos_pitalito`, coalesce(max(case when `sb`.`bodega` = 'Bodega Principal' then `sb`.`stock_minimo` end),0) AS `stock_min_principal`, coalesce(max(case when `sb`.`bodega` = 'Bodega Garzón' then `sb`.`stock_minimo` end),0) AS `stock_min_garzon`, coalesce(max(case when `sb`.`bodega` = 'Bodega Pitalito' then `sb`.`stock_minimo` end),0) AS `stock_min_pitalito`, CASE WHEN `a`.`tipo_articulo` = 'Consumible' THEN coalesce(sum(`sb`.`stock_actual`),0) ELSE coalesce(sum(`sb`.`activos_disponibles`),0) END AS `stock_total`, coalesce(avg(`sb`.`stock_minimo`),0) AS `stock_minimo_promedio`, CASE WHEN `a`.`tipo_articulo` = 'Consumible' THEN CASE WHEN coalesce(sum(`sb`.`stock_actual`),0) = 0 THEN 'sin_stock' WHEN coalesce(sum(`sb`.`stock_actual`),0) <= coalesce(avg(`sb`.`stock_minimo`),0) THEN 'stock_bajo' ELSE 'stock_ok' END ELSE 'activo_controlado' END AS `estado_stock`, coalesce(sum(`sb`.`stock_actual`),0) AS `total_consumibles`, coalesce(sum(`sb`.`activos_disponibles`),0) AS `total_activos` FROM (((`articulos` `a` left join `stock_bodegas` `sb` on(`a`.`id` = `sb`.`articulo_id`)) left join `categorias` `c` on(`a`.`categoria_id` = `c`.`id`)) left join `marcas` `m` on(`a`.`marca_id` = `m`.`id`)) WHERE `a`.`es_activo` = 1 GROUP BY `a`.`id`, `a`.`referencia`, `a`.`descripcion`, `a`.`tipo_articulo`, `c`.`nombre`, `m`.`nombre` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_stock_jerarquico`
--
DROP TABLE IF EXISTS `vista_stock_jerarquico`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_stock_jerarquico`  AS SELECT `c`.`nombre` AS `categoria_nombre`, `m`.`nombre` AS `marca_nombre`, `a`.`referencia` AS `referencia`, `a`.`descripcion` AS `descripcion`, `a`.`tipo_articulo` AS `tipo_articulo`, count(distinct `a`.`id`) AS `total_referencias`, sum(case when `a`.`tipo_articulo` = 'Consumible' then coalesce(`sb`.`stock_actual`,0) else 0 end) AS `total_consumibles`, sum(case when `a`.`tipo_articulo` = 'Consumible' then coalesce(`sb`.`stock_minimo`,0) else 0 end) AS `total_minimo_consumibles`, sum(case when `a`.`tipo_articulo` in ('Activo Fijo','Activo de Control') then coalesce(`sb`.`activos_disponibles`,0) else 0 end) AS `total_activos`, CASE WHEN sum(case when `a`.`tipo_articulo` = 'Consumible' then coalesce(`sb`.`stock_actual`,0) else 0 end) > 0 AND sum(case when `a`.`tipo_articulo` = 'Consumible' then coalesce(`sb`.`stock_actual`,0) else 0 end) <= sum(case when `a`.`tipo_articulo` = 'Consumible' then coalesce(`sb`.`stock_minimo`,0) else 0 end) THEN 'stock_bajo_categoria' ELSE 'stock_ok_categoria' END AS `alerta_categoria` FROM (((`categorias` `c` left join `articulos` `a` on(`c`.`id` = `a`.`categoria_id`)) left join `marcas` `m` on(`a`.`marca_id` = `m`.`id`)) left join `stock_bodegas` `sb` on(`a`.`id` = `sb`.`articulo_id`)) WHERE `a`.`es_activo` = 1 GROUP BY `c`.`nombre`, `m`.`nombre`, `a`.`referencia`, `a`.`descripcion`, `a`.`tipo_articulo` ORDER BY `c`.`nombre` ASC, `m`.`nombre` ASC, `a`.`referencia` ASC ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `actas`
--
ALTER TABLE `actas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario_creador_id` (`usuario_creador_id`),
  ADD KEY `entregado_por_id` (`entregado_por_id`),
  ADD KEY `recibido_por_id` (`recibido_por_id`),
  ADD KEY `auditor_id` (`auditor_id`);

--
-- Indices de la tabla `acta_detalles`
--
ALTER TABLE `acta_detalles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `acta_id` (`acta_id`),
  ADD KEY `inventario_id` (`inventario_id`);

--
-- Indices de la tabla `articulos`
--
ALTER TABLE `articulos`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_articulos_categoria` (`categoria_id`),
  ADD KEY `idx_articulos_marca` (`marca_id`),
  ADD KEY `idx_articulos_categoria_marca` (`categoria_id`,`marca_id`);

--
-- Indices de la tabla `asignaciones`
--
ALTER TABLE `asignaciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `inventario_id` (`inventario_id`),
  ADD KEY `sitio_venta_id` (`sitio_venta_id`),
  ADD KEY `usuario_asignador_id` (`usuario_asignador_id`),
  ADD KEY `fk_asignaciones_personal` (`tecnico_id`);

--
-- Indices de la tabla `categorias`
--
ALTER TABLE `categorias`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `asignacion_id` (`asignacion_id`),
  ADD KEY `sitio_venta_id` (`sitio_venta_id`),
  ADD KEY `usuario_receptor_id` (`usuario_receptor_id`),
  ADD KEY `fk_devoluciones_personal` (`tecnico_id`);

--
-- Indices de la tabla `geocoding_cache`
--
ALTER TABLE `geocoding_cache`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `direccion_hash` (`direccion_hash`);

--
-- Indices de la tabla `historial_inventario`
--
ALTER TABLE `historial_inventario`
  ADD PRIMARY KEY (`id`),
  ADD KEY `inventario_id` (`inventario_id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `asignacion_id` (`asignacion_id`),
  ADD KEY `devolucion_id` (`devolucion_id`);

--
-- Indices de la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD PRIMARY KEY (`id`),
  ADD KEY `usuario_id` (`usuario_id`),
  ADD KEY `idx_inventario_bodega_estado` (`bodega`,`estado`),
  ADD KEY `idx_inventario_articulo_id` (`articulo_id`),
  ADD KEY `idx_inventario_estado_asignacion` (`estado_asignacion`);

--
-- Indices de la tabla `marcas`
--
ALTER TABLE `marcas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notificaciones_usuario` (`usuario_id`,`leida`),
  ADD KEY `idx_notificaciones_tipo` (`tipo`,`creado_en`);

--
-- Indices de la tabla `personal`
--
ALTER TABLE `personal`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_personal_identificacion` (`identificacion`),
  ADD KEY `idx_personal_activo` (`activo`),
  ADD KEY `idx_personal_tipo` (`tipo`);

--
-- Indices de la tabla `sitios_venta`
--
ALTER TABLE `sitios_venta`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `codigo_sv` (`codigo_sv`),
  ADD KEY `idx_coordenadas` (`latitud`,`longitud`),
  ADD KEY `idx_ciudad_estado` (`ciudad`,`estado_sv`),
  ADD KEY `idx_sincronizacion` (`sincronizado_movil`,`ultima_actualizacion`),
  ADD KEY `idx_tipo_estado` (`tipo_sv`,`estado_sv`);

--
-- Indices de la tabla `stock_bodegas`
--
ALTER TABLE `stock_bodegas`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uk_articulo_bodega` (`articulo_id`,`bodega`);

--
-- Indices de la tabla `transferencias_bodegas`
--
ALTER TABLE `transferencias_bodegas`
  ADD PRIMARY KEY (`id`),
  ADD KEY `acta_id` (`acta_id`),
  ADD KEY `inventario_id` (`inventario_id`),
  ADD KEY `usuario_solicitante_id` (`usuario_solicitante_id`),
  ADD KEY `usuario_aprobador_id` (`usuario_aprobador_id`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `actas`
--
ALTER TABLE `actas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `acta_detalles`
--
ALTER TABLE `acta_detalles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `articulos`
--
ALTER TABLE `articulos`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT de la tabla `asignaciones`
--
ALTER TABLE `asignaciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categorias`
--
ALTER TABLE `categorias`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT de la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `geocoding_cache`
--
ALTER TABLE `geocoding_cache`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `historial_inventario`
--
ALTER TABLE `historial_inventario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `inventario`
--
ALTER TABLE `inventario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT de la tabla `marcas`
--
ALTER TABLE `marcas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `personal`
--
ALTER TABLE `personal`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `sitios_venta`
--
ALTER TABLE `sitios_venta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `stock_bodegas`
--
ALTER TABLE `stock_bodegas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `transferencias_bodegas`
--
ALTER TABLE `transferencias_bodegas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `actas`
--
ALTER TABLE `actas`
  ADD CONSTRAINT `actas_ibfk_1` FOREIGN KEY (`usuario_creador_id`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `actas_ibfk_2` FOREIGN KEY (`entregado_por_id`) REFERENCES `personal` (`id`),
  ADD CONSTRAINT `actas_ibfk_3` FOREIGN KEY (`recibido_por_id`) REFERENCES `personal` (`id`),
  ADD CONSTRAINT `actas_ibfk_4` FOREIGN KEY (`auditor_id`) REFERENCES `personal` (`id`);

--
-- Filtros para la tabla `acta_detalles`
--
ALTER TABLE `acta_detalles`
  ADD CONSTRAINT `acta_detalles_ibfk_1` FOREIGN KEY (`acta_id`) REFERENCES `actas` (`id`),
  ADD CONSTRAINT `acta_detalles_ibfk_2` FOREIGN KEY (`inventario_id`) REFERENCES `inventario` (`id`);

--
-- Filtros para la tabla `articulos`
--
ALTER TABLE `articulos`
  ADD CONSTRAINT `articulos_ibfk_1` FOREIGN KEY (`categoria_id`) REFERENCES `categorias` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `articulos_ibfk_2` FOREIGN KEY (`marca_id`) REFERENCES `marcas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Filtros para la tabla `asignaciones`
--
ALTER TABLE `asignaciones`
  ADD CONSTRAINT `asignaciones_ibfk_1` FOREIGN KEY (`inventario_id`) REFERENCES `inventario` (`id`),
  ADD CONSTRAINT `asignaciones_ibfk_3` FOREIGN KEY (`sitio_venta_id`) REFERENCES `sitios_venta` (`id`),
  ADD CONSTRAINT `asignaciones_ibfk_4` FOREIGN KEY (`usuario_asignador_id`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `fk_asignaciones_personal` FOREIGN KEY (`tecnico_id`) REFERENCES `personal` (`id`);

--
-- Filtros para la tabla `devoluciones`
--
ALTER TABLE `devoluciones`
  ADD CONSTRAINT `devoluciones_ibfk_1` FOREIGN KEY (`asignacion_id`) REFERENCES `asignaciones` (`id`),
  ADD CONSTRAINT `devoluciones_ibfk_3` FOREIGN KEY (`sitio_venta_id`) REFERENCES `sitios_venta` (`id`),
  ADD CONSTRAINT `devoluciones_ibfk_4` FOREIGN KEY (`usuario_receptor_id`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `fk_devoluciones_personal` FOREIGN KEY (`tecnico_id`) REFERENCES `personal` (`id`);

--
-- Filtros para la tabla `historial_inventario`
--
ALTER TABLE `historial_inventario`
  ADD CONSTRAINT `historial_inventario_ibfk_1` FOREIGN KEY (`inventario_id`) REFERENCES `inventario` (`id`),
  ADD CONSTRAINT `historial_inventario_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `historial_inventario_ibfk_3` FOREIGN KEY (`asignacion_id`) REFERENCES `asignaciones` (`id`),
  ADD CONSTRAINT `historial_inventario_ibfk_4` FOREIGN KEY (`devolucion_id`) REFERENCES `devoluciones` (`id`);

--
-- Filtros para la tabla `inventario`
--
ALTER TABLE `inventario`
  ADD CONSTRAINT `inventario_ibfk_1` FOREIGN KEY (`articulo_id`) REFERENCES `articulos` (`id`),
  ADD CONSTRAINT `inventario_ibfk_2` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`);

--
-- Filtros para la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD CONSTRAINT `notificaciones_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `stock_bodegas`
--
ALTER TABLE `stock_bodegas`
  ADD CONSTRAINT `stock_bodegas_ibfk_1` FOREIGN KEY (`articulo_id`) REFERENCES `articulos` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `transferencias_bodegas`
--
ALTER TABLE `transferencias_bodegas`
  ADD CONSTRAINT `transferencias_bodegas_ibfk_1` FOREIGN KEY (`acta_id`) REFERENCES `actas` (`id`),
  ADD CONSTRAINT `transferencias_bodegas_ibfk_2` FOREIGN KEY (`inventario_id`) REFERENCES `inventario` (`id`),
  ADD CONSTRAINT `transferencias_bodegas_ibfk_3` FOREIGN KEY (`usuario_solicitante_id`) REFERENCES `usuarios` (`id`),
  ADD CONSTRAINT `transferencias_bodegas_ibfk_4` FOREIGN KEY (`usuario_aprobador_id`) REFERENCES `usuarios` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
