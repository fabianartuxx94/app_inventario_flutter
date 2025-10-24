const mysql = require("../../DB/mysql");

class MapsController {
  
  // 🗺️ OBTENER TODOS LOS SITIOS DE VENTA (CON Y SIN COORDENADAS)
  async getSitiosVenta(req, res) {
    try {
      const sql = `
        SELECT 
          id,
          codigo_sv,
          sitio_venta,
          direccion,
          ciudad,
          barrio,
          latitud,
          longitud,
          tipo_sv,
          estado_sv,
          tecnologias_sv,
          geocoding_completo,
          precision_geocoding,
          ultima_actualizacion,
          -- Campos para Mapbox
          CASE 
            WHEN tipo_sv = 'PUNTO FIJO' THEN 'office'
            WHEN tipo_sv = 'TIENDA A TIENDA' THEN 'shop'
            ELSE 'warehouse'
          END as mapbox_icon,
          CASE 
            WHEN estado_sv = 'Activo' THEN 'green'
            WHEN estado_sv = 'Mantenimiento' THEN 'orange'
            ELSE 'red'
          END as mapbox_color,
          -- Indicador si tiene coordenadas
          CASE 
            WHEN latitud IS NOT NULL AND longitud IS NOT NULL THEN 1
            ELSE 0
          END as tiene_coordenadas
        FROM sitios_venta 
        WHERE estado_sv != 'Inactivo'
        ORDER BY ciudad, sitio_venta
      `;

      const sitios = await mysql.consultaDirecta(sql);
      
      res.json({
        success: true,
        data: sitios,
        total: sitios.length,
        con_coordenadas: sitios.filter(s => s.tiene_coordenadas).length,
        sin_coordenadas: sitios.filter(s => !s.tiene_coordenadas).length
      });

    } catch (error) {
      console.error('❌ Error en getSitiosVenta:', error);
      res.status(500).json({
        success: false,
        error: 'Error al cargar sitios de venta'
      });
    }
  }

  // 📍 OBTENER SITIOS CON COORDENADAS PARA EL MAPA
  async getSitiosConCoordenadas(req, res) {
    try {
      const sql = `
        SELECT 
          id,
          codigo_sv,
          sitio_venta,
          direccion,
          ciudad,
          barrio,
          latitud,
          longitud,
          tipo_sv,
          estado_sv,
          tecnologias_sv,
          CASE 
            WHEN tipo_sv = 'PUNTO FIJO' THEN 'office'
            WHEN tipo_sv = 'TIENDA A TIENDA' THEN 'shop'
            ELSE 'warehouse'
          END as mapbox_icon,
          CASE 
            WHEN estado_sv = 'Activo' THEN 'green'
            WHEN estado_sv = 'Mantenimiento' THEN 'orange'
            ELSE 'red'
          END as mapbox_color
        FROM sitios_venta 
        WHERE latitud IS NOT NULL 
          AND longitud IS NOT NULL 
          AND estado_sv != 'Inactivo'
        ORDER BY ciudad, sitio_venta
      `;

      const sitios = await mysql.consultaDirecta(sql);
      
      res.json({
        success: true,
        data: sitios,
        total: sitios.length
      });

    } catch (error) {
      console.error('❌ Error en getSitiosConCoordenadas:', error);
      res.status(500).json({
        success: false,
        error: 'Error al cargar sitios con coordenadas'
      });
    }
  }

  // 📱 ACTUALIZAR UBICACIÓN DESDE APP MÓVIL (TÉCNICOS)
  async actualizarUbicacionSitio(req, res) {
    try {
      const { id } = req.params;
      const { latitud, longitud, precision = 'exacta' } = req.body;

      // Validar datos requeridos
      if (!latitud || !longitud) {
        return res.status(400).json({
          success: false,
          error: 'Latitud y longitud son requeridos'
        });
      }

      // Validar rangos de coordenadas
      if (latitud < -90 || latitud > 90 || longitud < -180 || longitud > 180) {
        return res.status(400).json({
          success: false,
          error: 'Coordenadas fuera de rango válido'
        });
      }

      // Verificar que el sitio existe
      const sitioExistente = await mysql.uno('sitios_venta', id);
      
      if (!sitioExistente) {
        return res.status(404).json({
          success: false,
          error: 'Sitio de venta no encontrado'
        });
      }

      // Preparar datos para actualización
      const datosActualizacion = {
        latitud: parseFloat(latitud).toFixed(8),
        longitud: parseFloat(longitud).toFixed(8),
        geocoding_completo: 1,
        precision_geocoding: precision,
        sincronizado_movil: 1,
        ultima_actualizacion: new Date()
      };

      // Actualizar en base de datos
      await mysql.agregar('sitios_venta', { id: parseInt(id), ...datosActualizacion });

      // Opcional: Guardar en cache de geocoding
      await this.guardarEnGeocodingCache(sitioExistente, latitud, longitud, precision);

      res.json({
        success: true,
        message: 'Ubicación actualizada exitosamente',
        data: {
          id: parseInt(id),
          sitio_venta: sitioExistente.sitio_venta,
          latitud: datosActualizacion.latitud,
          longitud: datosActualizacion.longitud,
          precision: precision,
          actualizado_en: datosActualizacion.ultima_actualizacion
        }
      });

    } catch (error) {
      console.error('❌ Error en actualizarUbicacionSitio:', error);
      res.status(500).json({
        success: false,
        error: 'Error al actualizar ubicación'
      });
    }
  }

  // 💾 GUARDAR EN CACHE DE GEOCODING (OPCIONAL)
  async guardarEnGeocodingCache(sitio, latitud, longitud, precision) {
    try {
      const direccionCompleta = `${sitio.direccion || ''}, ${sitio.barrio || ''}, ${sitio.ciudad}`.trim();
      
      // Crear hash único de la dirección
      const crypto = require('crypto');
      const direccionHash = crypto.createHash('sha256').update(direccionCompleta).digest('hex');

      const cacheData = {
        direccion_hash: direccionHash,
        direccion_completa: direccionCompleta,
        latitud: latitud,
        longitud: longitud,
        precision_obtenida: precision,
        respuesta_json: JSON.stringify({
          source: 'mobile_gps',
          timestamp: new Date(),
          sitio_id: sitio.id
        })
      };

      await mysql.agregar('geocoding_cache', cacheData);

    } catch (error) {
      console.error('⚠️ Error guardando en cache de geocoding:', error);
      // No falla la operación principal si el cache falla
    }
  }

  // 📊 OBTENER ESTADÍSTICAS DE SITIOS
  async getEstadisticasSitios(req, res) {
    try {
      const sql = `
        SELECT 
          COUNT(*) as total_sitios,
          SUM(CASE WHEN latitud IS NOT NULL AND longitud IS NOT NULL THEN 1 ELSE 0 END) as con_coordenadas,
          SUM(CASE WHEN latitud IS NULL OR longitud IS NULL THEN 1 ELSE 0 END) as sin_coordenadas,
          COUNT(DISTINCT ciudad) as total_ciudades,
          estado_sv,
          tipo_sv
        FROM sitios_venta 
        WHERE estado_sv != 'Inactivo'
        GROUP BY estado_sv, tipo_sv
      `;

      const estadisticas = await mysql.consultaDirecta(sql);
      
      res.json({
        success: true,
        data: estadisticas
      });

    } catch (error) {
      console.error('❌ Error en getEstadisticasSitios:', error);
      res.status(500).json({
        success: false,
        error: 'Error al cargar estadísticas'
      });
    }
  }

  // 🔍 BUSCAR SITIOS POR CIUDAD O NOMBRE
  async buscarSitios(req, res) {
    try {
      const { ciudad, nombre, con_coordenadas } = req.query;
      
      let sql = `
        SELECT 
          id,
          codigo_sv,
          sitio_venta,
          direccion,
          ciudad,
          barrio,
          latitud,
          longitud,
          tipo_sv,
          estado_sv
        FROM sitios_venta 
        WHERE estado_sv != 'Inactivo'
      `;

      const params = [];

      if (ciudad) {
        sql += ` AND ciudad LIKE ?`;
        params.push(`%${ciudad}%`);
      }

      if (nombre) {
        sql += ` AND (sitio_venta LIKE ? OR codigo_sv LIKE ?)`;
        params.push(`%${nombre}%`, `%${nombre}%`);
      }

      if (con_coordenadas === 'true') {
        sql += ` AND latitud IS NOT NULL AND longitud IS NOT NULL`;
      }

      sql += ` ORDER BY ciudad, sitio_venta`;

      const sitios = await mysql.consultaDirecta(sql, params);
      
      res.json({
        success: true,
        data: sitios,
        total: sitios.length
      });

    } catch (error) {
      console.error('❌ Error en buscarSitios:', error);
      res.status(500).json({
        success: false,
        error: 'Error al buscar sitios'
      });
    }
  }
}

module.exports = new MapsController();