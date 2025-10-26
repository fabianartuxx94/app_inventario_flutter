import 'package:flutter/material.dart';
import 'package:frontend/models/sitio_venta_model.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/auth_provider.dart';

class DetallesSitioCard extends StatelessWidget {
  final SitioVenta sitio;
  final VoidCallback? onActualizarUbicacion;
  final VoidCallback? onCerrar;

  const DetallesSitioCard({
    super.key,
    required this.sitio,
    this.onActualizarUbicacion,
    this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea( // ✅ Usar SafeArea para manejar automáticamente las áreas seguras
      top: false, // No aplicar safe area en la parte superior
      minimum: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF001F5E).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _obtenerColorContainerEstado(sitio.estadoSv),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _obtenerIconoEstado(sitio.estadoSv),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sitio.sitioVenta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sitio.codigoSv,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('📍', sitio.direccionCompleta),
              _buildInfoRow('🏙️', 'Ciudad: ${sitio.ciudad}'),
              _buildInfoRow('🏪', 'Tipo: ${sitio.tipoSv}'),
              _buildInfoRow('⚡', 'Estado: ${sitio.estadoSv}'),
              if (sitio.tecnologiasSv != null && sitio.tecnologiasSv!.isNotEmpty)
                _buildInfoRow('💻', 'Tecnologías: ${sitio.tecnologiasSv}'),
              if (sitio.latitud != null && sitio.longitud != null)
                _buildInfoRow('📌', 'Coordenadas: ${sitio.latitud!.toStringAsFixed(6)}, ${sitio.longitud!.toStringAsFixed(6)}'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCerrar ?? () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (Provider.of<AuthProvider>(context, listen: false).isTecnico)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onActualizarUbicacion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gps_fixed, size: 18),
                            SizedBox(width: 8),
                            Text('Ubicación'),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // ✅ Espacio adicional para mayor seguridad
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _obtenerColorContainerEstado(String estado) {
    switch (estado) {
      case 'Activo':
        return Colors.green;
      case 'Mantenimiento':
        return Colors.orange;
      case 'Inactivo':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _obtenerIconoEstado(String estado) {
    switch (estado) {
      case 'Activo':
        return Icons.check_circle;
      case 'Mantenimiento':
        return Icons.build;
      case 'Inactivo':
        return Icons.pause_circle;
      default:
        return Icons.help;
    }
  }
}