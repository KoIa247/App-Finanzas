/// Catalogo de fabrica. Todo esto es editable desde la app; son solo los
/// valores con los que arranca una instalacion nueva.
///
/// Las categorias, reglas y cuentas salen del sistema que ya venia corriendo
/// sobre Google Sheets, asi que estan probadas contra correos reales del BCP.
library;

import '../../domain/catalogo.dart';
import '../../domain/finanzas.dart';

/// Categorias y subcategorias de fabrica.
const List<Categoria> categoriasSemilla = [
  Categoria(categoria: 'Alimentacion', subcategoria: 'Delivery', tipoAplicable: 'GASTO', icono: '🛵', color: '#F97316', orden: 10),
  Categoria(categoria: 'Alimentacion', subcategoria: 'Restaurantes', tipoAplicable: 'GASTO', icono: '🍽', color: '#F97316', orden: 11),
  Categoria(categoria: 'Alimentacion', subcategoria: 'Supermercado', tipoAplicable: 'GASTO', icono: '🛒', color: '#F97316', orden: 12),
  Categoria(categoria: 'Alimentacion', subcategoria: 'Cafeteria', tipoAplicable: 'GASTO', icono: '☕', color: '#F97316', orden: 13),
  Categoria(categoria: 'Transporte', subcategoria: 'Taxi / Apps', tipoAplicable: 'GASTO', icono: '🚗', color: '#0EA5E9', orden: 20),
  Categoria(categoria: 'Transporte', subcategoria: 'Combustible', tipoAplicable: 'GASTO', icono: '⛽', color: '#0EA5E9', orden: 21),
  Categoria(categoria: 'Transporte', subcategoria: 'Estacionamiento', tipoAplicable: 'GASTO', icono: '🅿', color: '#0EA5E9', orden: 22),
  Categoria(categoria: 'Transporte', subcategoria: 'Mantenimiento', tipoAplicable: 'GASTO', icono: '🔧', color: '#0EA5E9', orden: 23),
  Categoria(categoria: 'Vivienda', subcategoria: 'Alquiler', tipoAplicable: 'GASTO', icono: '🏠', color: '#8B5CF6', orden: 30),
  Categoria(categoria: 'Vivienda', subcategoria: 'Servicios', tipoAplicable: 'GASTO', icono: '💡', color: '#8B5CF6', orden: 31),
  Categoria(categoria: 'Vivienda', subcategoria: 'Internet / Telefono', tipoAplicable: 'GASTO', icono: '📶', color: '#8B5CF6', orden: 32),
  Categoria(categoria: 'Vivienda', subcategoria: 'Mantenimiento', tipoAplicable: 'GASTO', icono: '🧰', color: '#8B5CF6', orden: 33),
  Categoria(categoria: 'Salud', subcategoria: 'Consultas', tipoAplicable: 'GASTO', icono: '🩺', color: '#10B981', orden: 40),
  Categoria(categoria: 'Salud', subcategoria: 'Farmacia', tipoAplicable: 'GASTO', icono: '💊', color: '#10B981', orden: 41),
  Categoria(categoria: 'Salud', subcategoria: 'Seguros', tipoAplicable: 'GASTO', icono: '🛡', color: '#10B981', orden: 42),
  Categoria(categoria: 'Salud', subcategoria: 'Gimnasio / Deporte', tipoAplicable: 'GASTO', icono: '🏋', color: '#10B981', orden: 43),
  Categoria(categoria: 'Suscripciones', subcategoria: 'Software / IA', tipoAplicable: 'GASTO', icono: '🤖', color: '#6366F1', orden: 50),
  Categoria(categoria: 'Suscripciones', subcategoria: 'Streaming', tipoAplicable: 'GASTO', icono: '🎬', color: '#6366F1', orden: 51),
  Categoria(categoria: 'Suscripciones', subcategoria: 'Nube / Storage', tipoAplicable: 'GASTO', icono: '☁', color: '#6366F1', orden: 52),
  Categoria(categoria: 'Suscripciones', subcategoria: 'Profesional', tipoAplicable: 'GASTO', icono: '💼', color: '#6366F1', orden: 53),
  Categoria(categoria: 'Entretenimiento', subcategoria: 'Videojuegos', tipoAplicable: 'GASTO', icono: '🎮', color: '#EC4899', orden: 60),
  Categoria(categoria: 'Entretenimiento', subcategoria: 'Salidas', tipoAplicable: 'GASTO', icono: '🍸', color: '#EC4899', orden: 61),
  Categoria(categoria: 'Entretenimiento', subcategoria: 'Apuestas', tipoAplicable: 'GASTO', icono: '🎲', color: '#EC4899', orden: 62),
  Categoria(categoria: 'Entretenimiento', subcategoria: 'Viajes', tipoAplicable: 'GASTO', icono: '✈', color: '#EC4899', orden: 63),
  Categoria(categoria: 'Entretenimiento', subcategoria: 'Conciertos', tipoAplicable: 'GASTO', icono: '🎤', color: '#EC4899', orden: 64),
  Categoria(categoria: 'Compras', subcategoria: 'Ropa', tipoAplicable: 'GASTO', icono: '👕', color: '#F59E0B', orden: 70),
  Categoria(categoria: 'Compras', subcategoria: 'Tecnologia', tipoAplicable: 'GASTO', icono: '💻', color: '#F59E0B', orden: 71),
  Categoria(categoria: 'Compras', subcategoria: 'Hogar', tipoAplicable: 'GASTO', icono: '🛋', color: '#F59E0B', orden: 72),
  Categoria(categoria: 'Compras', subcategoria: 'Otros', tipoAplicable: 'GASTO', icono: '📦', color: '#F59E0B', orden: 73),
  Categoria(categoria: 'Envios a personas', subcategoria: 'Familia', tipoAplicable: 'GASTO', icono: '👪', color: '#14B8A6', orden: 80),
  Categoria(categoria: 'Envios a personas', subcategoria: 'Amigos', tipoAplicable: 'GASTO', icono: '🤝', color: '#14B8A6', orden: 81),
  Categoria(categoria: 'Financiero', subcategoria: 'Comisiones', tipoAplicable: 'GASTO', icono: '🏦', color: '#64748B', orden: 95),
  Categoria(categoria: 'Financiero', subcategoria: 'Intereses', tipoAplicable: 'GASTO', icono: '📉', color: '#64748B', orden: 96),
  Categoria(categoria: 'Financiero', subcategoria: 'Impuestos', tipoAplicable: 'GASTO', icono: '🧮', color: '#64748B', orden: 97),
  Categoria(categoria: 'Sin clasificar', subcategoria: 'Sin clasificar', tipoAplicable: 'GASTO', icono: '❓', color: '#94A3B8', orden: 999),
  Categoria(categoria: 'Ingresos', subcategoria: 'Sueldo', tipoAplicable: 'INGRESO', icono: '💵', color: '#22C55E', orden: 100),
  Categoria(categoria: 'Ingresos', subcategoria: 'Bonos', tipoAplicable: 'INGRESO', icono: '🎯', color: '#22C55E', orden: 101),
  Categoria(categoria: 'Ingresos', subcategoria: 'Gratificacion', tipoAplicable: 'INGRESO', icono: '🎁', color: '#22C55E', orden: 102),
  Categoria(categoria: 'Ingresos', subcategoria: 'CTS', tipoAplicable: 'INGRESO', icono: '🏦', color: '#22C55E', orden: 103),
  Categoria(categoria: 'Ingresos', subcategoria: 'Utilidades', tipoAplicable: 'INGRESO', icono: '📈', color: '#22C55E', orden: 104),
  Categoria(categoria: 'Ingresos', subcategoria: 'Reembolsos', tipoAplicable: 'INGRESO', icono: '↩', color: '#22C55E', orden: 105),
  Categoria(categoria: 'Ingresos', subcategoria: 'Transferencias recibidas', tipoAplicable: 'INGRESO', icono: '📥', color: '#22C55E', orden: 106),
  Categoria(categoria: 'Ingresos', subcategoria: 'Otros', tipoAplicable: 'INGRESO', icono: '➕', color: '#22C55E', orden: 107),
  Categoria(categoria: 'Inversiones', subcategoria: 'Aportes', tipoAplicable: 'NEUTRO', icono: '📈', color: '#3B82F6', orden: 110),
  Categoria(categoria: 'Inversiones', subcategoria: 'Retiros', tipoAplicable: 'NEUTRO', icono: '📉', color: '#3B82F6', orden: 111),
  Categoria(categoria: 'Movimientos internos', subcategoria: 'Transferencia entre cuentas', tipoAplicable: 'NEUTRO', icono: '🔁', color: '#94A3B8', orden: 120),
  Categoria(categoria: 'Movimientos internos', subcategoria: 'Pago de tarjeta', tipoAplicable: 'NEUTRO', icono: '💳', color: '#94A3B8', orden: 121),
  Categoria(categoria: 'Movimientos internos', subcategoria: 'Retiro de efectivo', tipoAplicable: 'NEUTRO', icono: '🏧', color: '#94A3B8', orden: 122),
  Categoria(categoria: 'Movimientos internos', subcategoria: 'Transferencia a terceros', tipoAplicable: 'NEUTRO', icono: '↗', color: '#94A3B8', orden: 123),
];

/// Reglas de clasificacion de fabrica.
///
/// Se evaluan por prioridad ascendente y gana la primera que calza. Ese orden
/// es lo que hace que "GOOGLE WORKSPACE" (54) le gane al comodin "GOOGLE" (60).
const List<Regla> reglasSemilla = [
  Regla(id: 'REG-001', campo: 'comercio', operador: 'contiene', valor: 'TRII', tipoResultado: 'APORTE_INVERSION', categoria: 'Inversiones', subcategoria: 'Aportes', cuentaDestino: 'INV_TRII', recurrente: false, prioridad: 5, origen: 'SEMILLA'),
  Regla(id: 'REG-002', campo: 'comercio', operador: 'contiene', valor: 'RAPPI PRO', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Streaming', cuentaDestino: '', recurrente: true, prioridad: 10, origen: 'SEMILLA'),
  Regla(id: 'REG-003', campo: 'comercio', operador: 'contiene', valor: 'RAPPI', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Delivery', cuentaDestino: '', recurrente: false, prioridad: 20, origen: 'SEMILLA'),
  Regla(id: 'REG-004', campo: 'comercio', operador: 'contiene', valor: 'PEDIDOSYA', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Delivery', cuentaDestino: '', recurrente: false, prioridad: 21, origen: 'SEMILLA'),
  Regla(id: 'REG-005', campo: 'comercio', operador: 'contiene', valor: 'BESO FRANCES', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Restaurantes', cuentaDestino: '', recurrente: false, prioridad: 22, origen: 'SEMILLA'),
  Regla(id: 'REG-006', campo: 'comercio', operador: 'contiene', valor: 'REGATAS', tipoResultado: '', categoria: 'Salud', subcategoria: 'Gimnasio / Deporte', cuentaDestino: '', recurrente: false, prioridad: 23, origen: 'SEMILLA'),
  Regla(id: 'REG-007', campo: 'comercio', operador: 'contiene', valor: 'WONG', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Supermercado', cuentaDestino: '', recurrente: false, prioridad: 24, origen: 'SEMILLA'),
  Regla(id: 'REG-008', campo: 'comercio', operador: 'contiene', valor: 'METRO', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Supermercado', cuentaDestino: '', recurrente: false, prioridad: 25, origen: 'SEMILLA'),
  Regla(id: 'REG-009', campo: 'comercio', operador: 'contiene', valor: 'PLAZA VEA', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Supermercado', cuentaDestino: '', recurrente: false, prioridad: 26, origen: 'SEMILLA'),
  Regla(id: 'REG-010', campo: 'comercio', operador: 'contiene', valor: 'TOTTUS', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Supermercado', cuentaDestino: '', recurrente: false, prioridad: 27, origen: 'SEMILLA'),
  Regla(id: 'REG-011', campo: 'comercio', operador: 'contiene', valor: 'VIVANDA', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Supermercado', cuentaDestino: '', recurrente: false, prioridad: 28, origen: 'SEMILLA'),
  Regla(id: 'REG-012', campo: 'comercio', operador: 'contiene', valor: 'STARBUCKS', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Cafeteria', cuentaDestino: '', recurrente: false, prioridad: 29, origen: 'SEMILLA'),
  Regla(id: 'REG-013', campo: 'comercio', operador: 'contiene', valor: 'GRUPO CORDILLERA', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Cafeteria', cuentaDestino: '', recurrente: false, prioridad: 30, origen: 'SEMILLA'),
  Regla(id: 'REG-014', campo: 'comercio', operador: 'contiene', valor: 'EDO SUSHI', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Restaurantes', cuentaDestino: '', recurrente: false, prioridad: 30, origen: 'SEMILLA'),
  Regla(id: 'REG-015', campo: 'comercio', operador: 'contiene', valor: 'KFC', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Restaurantes', cuentaDestino: '', recurrente: false, prioridad: 31, origen: 'SEMILLA'),
  Regla(id: 'REG-016', campo: 'comercio', operador: 'contiene', valor: 'MAKOTO', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Restaurantes', cuentaDestino: '', recurrente: false, prioridad: 32, origen: 'SEMILLA'),
  Regla(id: 'REG-017', campo: 'comercio', operador: 'contiene', valor: 'POKEBOSS', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Restaurantes', cuentaDestino: '', recurrente: false, prioridad: 33, origen: 'SEMILLA'),
  Regla(id: 'REG-018', campo: 'comercio', operador: 'contiene', valor: 'ASADOS HECTOR', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Restaurantes', cuentaDestino: '', recurrente: false, prioridad: 34, origen: 'SEMILLA'),
  Regla(id: 'REG-019', campo: 'comercio', operador: 'contiene', valor: 'SARGENTO PIMIE', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Restaurantes', cuentaDestino: '', recurrente: false, prioridad: 35, origen: 'SEMILLA'),
  Regla(id: 'REG-020', campo: 'comercio', operador: 'contiene', valor: 'KANAE', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Restaurantes', cuentaDestino: '', recurrente: false, prioridad: 36, origen: 'SEMILLA'),
  Regla(id: 'REG-021', campo: 'comercio', operador: 'contiene', valor: 'SIENNA BAKERY', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Cafeteria', cuentaDestino: '', recurrente: false, prioridad: 37, origen: 'SEMILLA'),
  Regla(id: 'REG-022', campo: 'comercio', operador: 'contiene', valor: 'ROSEN', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Cafeteria', cuentaDestino: '', recurrente: false, prioridad: 38, origen: 'SEMILLA'),
  Regla(id: 'REG-023', campo: 'comercio', operador: 'contiene', valor: 'BACKUS', tipoResultado: '', categoria: 'Alimentacion', subcategoria: 'Delivery', cuentaDestino: '', recurrente: false, prioridad: 39, origen: 'SEMILLA'),
  Regla(id: 'REG-024', campo: 'comercio', operador: 'contiene', valor: 'UBER', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Taxi / Apps', cuentaDestino: '', recurrente: false, prioridad: 40, origen: 'SEMILLA'),
  Regla(id: 'REG-025', campo: 'comercio', operador: 'contiene', valor: 'DLC*RIDES', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Taxi / Apps', cuentaDestino: '', recurrente: false, prioridad: 41, origen: 'SEMILLA'),
  Regla(id: 'REG-026', campo: 'comercio', operador: 'contiene', valor: 'CABIFY', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Taxi / Apps', cuentaDestino: '', recurrente: false, prioridad: 42, origen: 'SEMILLA'),
  Regla(id: 'REG-027', campo: 'comercio', operador: 'contiene', valor: 'BEAT', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Taxi / Apps', cuentaDestino: '', recurrente: false, prioridad: 43, origen: 'SEMILLA'),
  Regla(id: 'REG-028', campo: 'comercio', operador: 'contiene', valor: 'APPARKA', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Estacionamiento', cuentaDestino: '', recurrente: false, prioridad: 44, origen: 'SEMILLA'),
  Regla(id: 'REG-029', campo: 'comercio', operador: 'contiene', valor: 'RIOT GAMES', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Videojuegos', cuentaDestino: '', recurrente: false, prioridad: 45, origen: 'SEMILLA'),
  Regla(id: 'REG-030', campo: 'comercio', operador: 'contiene', valor: 'SERVICENTRO', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Combustible', cuentaDestino: '', recurrente: false, prioridad: 45, origen: 'SEMILLA'),
  Regla(id: 'REG-031', campo: 'comercio', operador: 'contiene', valor: 'DOCTOR LIFE', tipoResultado: '', categoria: 'Salud', subcategoria: 'Consultas', cuentaDestino: '', recurrente: false, prioridad: 46, origen: 'SEMILLA'),
  Regla(id: 'REG-032', campo: 'comercio', operador: 'contiene', valor: 'PRIMAX', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Combustible', cuentaDestino: '', recurrente: false, prioridad: 46, origen: 'SEMILLA'),
  Regla(id: 'REG-033', campo: 'comercio', operador: 'contiene', valor: 'REPSOL', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Combustible', cuentaDestino: '', recurrente: false, prioridad: 47, origen: 'SEMILLA'),
  Regla(id: 'REG-034', campo: 'comercio', operador: 'contiene', valor: 'CLINICA', tipoResultado: '', categoria: 'Salud', subcategoria: 'Consultas', cuentaDestino: '', recurrente: false, prioridad: 47, origen: 'SEMILLA'),
  Regla(id: 'REG-035', campo: 'comercio', operador: 'contiene', valor: 'RESOCENTRO', tipoResultado: '', categoria: 'Salud', subcategoria: 'Consultas', cuentaDestino: '', recurrente: false, prioridad: 48, origen: 'SEMILLA'),
  Regla(id: 'REG-036', campo: 'comercio', operador: 'contiene', valor: 'YOUTUBEPREMIUM', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Streaming', cuentaDestino: '', recurrente: true, prioridad: 48, origen: 'SEMILLA'),
  Regla(id: 'REG-037', campo: 'comercio', operador: 'contiene', valor: 'ES SMILE', tipoResultado: '', categoria: 'Salud', subcategoria: 'Consultas', cuentaDestino: '', recurrente: false, prioridad: 49, origen: 'SEMILLA'),
  Regla(id: 'REG-038', campo: 'comercio', operador: 'contiene', valor: 'YOUTUBE PREMIUM', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Streaming', cuentaDestino: '', recurrente: true, prioridad: 49, origen: 'SEMILLA'),
  Regla(id: 'REG-039', campo: 'comercio', operador: 'contiene', valor: 'ANTHROPIC', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Software / IA', cuentaDestino: '', recurrente: true, prioridad: 50, origen: 'SEMILLA'),
  Regla(id: 'REG-040', campo: 'comercio', operador: 'contiene', valor: 'OPENAI', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Software / IA', cuentaDestino: '', recurrente: true, prioridad: 51, origen: 'SEMILLA'),
  Regla(id: 'REG-041', campo: 'comercio', operador: 'contiene', valor: 'UX PILOT', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Software / IA', cuentaDestino: '', recurrente: true, prioridad: 52, origen: 'SEMILLA'),
  Regla(id: 'REG-042', campo: 'comercio', operador: 'contiene', valor: 'GOOGLE *GOOGLE ONE', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Nube / Storage', cuentaDestino: '', recurrente: true, prioridad: 53, origen: 'SEMILLA'),
  Regla(id: 'REG-043', campo: 'comercio', operador: 'contiene', valor: 'GOOGLE WORKSPACE', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Profesional', cuentaDestino: '', recurrente: true, prioridad: 54, origen: 'SEMILLA'),
  Regla(id: 'REG-044', campo: 'comercio', operador: 'contiene', valor: 'APPLE.COM/BILL', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Software / IA', cuentaDestino: '', recurrente: true, prioridad: 55, origen: 'SEMILLA'),
  Regla(id: 'REG-045', campo: 'comercio', operador: 'contiene', valor: 'LINKEDIN', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Profesional', cuentaDestino: '', recurrente: true, prioridad: 56, origen: 'SEMILLA'),
  Regla(id: 'REG-046', campo: 'comercio', operador: 'contiene', valor: 'NETFLIX', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Streaming', cuentaDestino: '', recurrente: true, prioridad: 57, origen: 'SEMILLA'),
  Regla(id: 'REG-047', campo: 'comercio', operador: 'contiene', valor: 'SPOTIFY', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Streaming', cuentaDestino: '', recurrente: true, prioridad: 58, origen: 'SEMILLA'),
  Regla(id: 'REG-048', campo: 'comercio', operador: 'contiene', valor: 'DISNEY', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Streaming', cuentaDestino: '', recurrente: true, prioridad: 59, origen: 'SEMILLA'),
  Regla(id: 'REG-049', campo: 'comercio', operador: 'contiene', valor: 'GOOGLE', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Software / IA', cuentaDestino: '', recurrente: true, prioridad: 60, origen: 'SEMILLA'),
  Regla(id: 'REG-050', campo: 'comercio', operador: 'contiene', valor: 'STEAM', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Videojuegos', cuentaDestino: '', recurrente: false, prioridad: 60, origen: 'SEMILLA'),
  Regla(id: 'REG-051', campo: 'comercio', operador: 'contiene', valor: 'APPLE', tipoResultado: '', categoria: 'Suscripciones', subcategoria: 'Software / IA', cuentaDestino: '', recurrente: true, prioridad: 61, origen: 'SEMILLA'),
  Regla(id: 'REG-052', campo: 'comercio', operador: 'contiene', valor: 'DISCORD', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Videojuegos', cuentaDestino: '', recurrente: false, prioridad: 61, origen: 'SEMILLA'),
  Regla(id: 'REG-053', campo: 'comercio', operador: 'contiene', valor: 'PLAYSTATION', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Videojuegos', cuentaDestino: '', recurrente: false, prioridad: 62, origen: 'SEMILLA'),
  Regla(id: 'REG-054', campo: 'comercio', operador: 'contiene', valor: 'BET365', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Apuestas', cuentaDestino: '', recurrente: false, prioridad: 63, origen: 'SEMILLA'),
  Regla(id: 'REG-055', campo: 'comercio', operador: 'contiene', valor: 'LATAM', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Viajes', cuentaDestino: '', recurrente: false, prioridad: 64, origen: 'SEMILLA'),
  Regla(id: 'REG-056', campo: 'comercio', operador: 'contiene', valor: 'BOOKING', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Viajes', cuentaDestino: '', recurrente: false, prioridad: 65, origen: 'SEMILLA'),
  Regla(id: 'REG-057', campo: 'comercio', operador: 'contiene', valor: 'REFUGIO', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Salidas', cuentaDestino: '', recurrente: false, prioridad: 66, origen: 'SEMILLA'),
  Regla(id: 'REG-058', campo: 'comercio', operador: 'contiene', valor: 'TELETICKET', tipoResultado: '', categoria: 'Entretenimiento', subcategoria: 'Conciertos', cuentaDestino: '', recurrente: false, prioridad: 67, origen: 'SEMILLA'),
  Regla(id: 'REG-059', campo: 'comercio', operador: 'contiene', valor: 'SUPERTEX', tipoResultado: '', categoria: 'Compras', subcategoria: 'Ropa', cuentaDestino: '', recurrente: false, prioridad: 70, origen: 'SEMILLA'),
  Regla(id: 'REG-060', campo: 'comercio', operador: 'contiene', valor: 'EL POLO SPORT', tipoResultado: '', categoria: 'Compras', subcategoria: 'Ropa', cuentaDestino: '', recurrente: false, prioridad: 71, origen: 'SEMILLA'),
  Regla(id: 'REG-061', campo: 'comercio', operador: 'contiene', valor: 'FALABELLA', tipoResultado: '', categoria: 'Compras', subcategoria: 'Otros', cuentaDestino: '', recurrente: false, prioridad: 72, origen: 'SEMILLA'),
  Regla(id: 'REG-062', campo: 'comercio', operador: 'contiene', valor: 'MERCADOPAGO', tipoResultado: '', categoria: 'Compras', subcategoria: 'Otros', cuentaDestino: '', recurrente: false, prioridad: 73, origen: 'SEMILLA'),
  Regla(id: 'REG-063', campo: 'comercio', operador: 'contiene', valor: 'COOLBOX', tipoResultado: '', categoria: 'Compras', subcategoria: 'Tecnologia', cuentaDestino: '', recurrente: false, prioridad: 74, origen: 'SEMILLA'),
  Regla(id: 'REG-064', campo: 'comercio', operador: 'contiene', valor: 'AMAZON', tipoResultado: '', categoria: 'Compras', subcategoria: 'Otros', cuentaDestino: '', recurrente: false, prioridad: 75, origen: 'SEMILLA'),
  Regla(id: 'REG-065', campo: 'comercio', operador: 'contiene', valor: 'MERCADO PAGO', tipoResultado: '', categoria: 'Compras', subcategoria: 'Otros', cuentaDestino: '', recurrente: false, prioridad: 76, origen: 'SEMILLA'),
  Regla(id: 'REG-066', campo: 'comercio', operador: 'contiene', valor: 'CC POLO', tipoResultado: '', categoria: 'Transporte', subcategoria: 'Estacionamiento', cuentaDestino: '', recurrente: false, prioridad: 77, origen: 'SEMILLA'),
  Regla(id: 'REG-067', campo: 'comercio', operador: 'empieza', valor: 'PLIN-', tipoResultado: '', categoria: 'Envios a personas', subcategoria: 'Amigos', cuentaDestino: '', recurrente: false, prioridad: 80, origen: 'SEMILLA'),
];

/// Remitentes autorizados. SOLO BANCOS, nunca comercios.
///
/// El gasto real es el que cobra el banco, no la boleta que manda la tienda: el
/// comercio puede mandar la factura antes de que el cargo exista, por un monto
/// sin propina o sin descuento, o mandarla dos veces. Y si entraran las dos
/// fuentes, cada compra se registraria dos veces.
///
/// Agregar Rappi, una tienda o una app de delivery romperia el sistema en
/// silencio: los totales del mes saldrian inflados sin que nada avise.
const List<Remitente> remitentesSemilla = [
  Remitente(
    remitente: 'notificaciones@notificacionesbcp.com.pe',
    banco: 'BCP',
    parser: 'BCP',
    notas: 'Servicio de Notificaciones BCP',
  ),
  Remitente(
    remitente: 'notificaciones@credito.com.pe',
    banco: 'BCP',
    parser: 'BCP',
    notas: 'Remitente alterno BCP',
  ),
  Remitente(
    remitente: 'bcpzonasegura@bcp.com.pe',
    banco: 'BCP',
    parser: 'BCP',
    activo: false,
    notas: 'Activar solo si recibes correos de aqui',
  ),
  Remitente(
    remitente: 'notificaciones@interbank.pe',
    banco: 'Interbank',
    parser: 'GENERICO',
    activo: false,
    notas: 'Activar cuando tengas cuenta Interbank',
  ),
  Remitente(
    remitente: 'no-reply@bbva.pe',
    banco: 'BBVA',
    parser: 'GENERICO',
    activo: false,
    notas: 'Plantilla generica',
  ),
  Remitente(
    remitente: 'notificaciones@scotiabank.com.pe',
    banco: 'Scotiabank',
    parser: 'GENERICO',
    activo: false,
    notas: 'Plantilla generica',
  ),
  Remitente(
    remitente: 'servicios@dinersclub.com.pe',
    banco: 'Diners',
    parser: 'GENERICO',
    activo: false,
    notas: 'Plantilla generica',
  ),
  Remitente(
    remitente: 'notificaciones@yape.com.pe',
    banco: 'Yape',
    parser: 'GENERICO',
    activo: false,
    notas: 'Yape manda push, no correo. Activar solo si te llegan.',
  ),
];

/// Cuentas de fabrica.
///
/// Solo queda la de efectivo, que todo el mundo necesita. Las tarjetas y
/// cuentas las agrega cada usuario con sus propios ultimos 4 digitos: son
/// justamente lo que conecta cada correo con la cuenta correcta.
const List<Cuenta> cuentasSemilla = [
  Cuenta(
    id: 'EFECTIVO',
    nombre: 'Efectivo',
    banco: '-',
    tipo: 'EFECTIVO',
    moneda: 'PEN',
  ),
];

/// Plantillas de ingreso de fabrica, con los conceptos del regimen laboral
/// peruano: quincena, fin de mes, gratificacion (julio y diciembre), CTS
/// (mayo y noviembre) y utilidades.
///
/// El banco no notifica los abonos de sueldo por correo, asi que los ingresos
/// los registra el usuario con un toque. Los montos son solo sugerencias.
const List<PlantillaIngreso> plantillasSemilla = [
  PlantillaIngreso(
    id: 'ING_QUINCENA',
    nombre: 'Pago quincena',
    subcategoria: 'Sueldo',
    diaAproximado: 15,
    frecuencia: 'MENSUAL',
    orden: 1,
  ),
  PlantillaIngreso(
    id: 'ING_FIN_MES',
    nombre: 'Pago fin de mes',
    subcategoria: 'Sueldo',
    diaAproximado: 30,
    frecuencia: 'MENSUAL',
    orden: 2,
  ),
  PlantillaIngreso(
    id: 'ING_GRATI',
    nombre: 'Gratificacion',
    subcategoria: 'Gratificacion',
    diaAproximado: 15,
    frecuencia: 'SEMESTRAL',
    orden: 3,
  ),
  PlantillaIngreso(
    id: 'ING_CTS',
    nombre: 'CTS',
    subcategoria: 'CTS',
    diaAproximado: 15,
    frecuencia: 'SEMESTRAL',
    orden: 4,
  ),
  PlantillaIngreso(
    id: 'ING_UTILIDADES',
    nombre: 'Utilidades',
    subcategoria: 'Utilidades',
    diaAproximado: 31,
    frecuencia: 'ANUAL',
    orden: 5,
  ),
  PlantillaIngreso(
    id: 'ING_BONO',
    nombre: 'Bono',
    subcategoria: 'Bonos',
    frecuencia: 'EVENTUAL',
    orden: 6,
  ),
  PlantillaIngreso(
    id: 'ING_REEMBOLSO',
    nombre: 'Reembolso',
    subcategoria: 'Reembolsos',
    frecuencia: 'EVENTUAL',
    orden: 7,
  ),
  PlantillaIngreso(
    id: 'ING_OTRO',
    nombre: 'Otro ingreso',
    subcategoria: 'Otros',
    frecuencia: 'EVENTUAL',
    orden: 8,
  ),
];

/// Parametros de fabrica. Clave -> [valor, descripcion].
const Map<String, List<String>> configSemilla = {
  'zona_horaria': ['America/Lima', 'Zona horaria para fechas y horas'],
  'moneda_base': ['PEN', 'Moneda de consolidacion del patrimonio'],
  'dias_busqueda_incremental': [
    '5',
    'Dias hacia atras que revisa cada sincronizacion'
  ],
  'max_correos_por_corrida': [
    '150',
    'Tope de mensajes por ejecucion, para no agotar la cuota de Gmail'
  ],
  'tc_por_defecto': ['3.75', 'Tipo de cambio de respaldo si no hay conexion'],
  'umbral_alerta_presupuesto': [
    '0.85',
    'Porcentaje a partir del cual se avisa (0.85 = 85%)'
  ],
  'cuenta_efectivo': ['EFECTIVO', 'Cuenta usada para los retiros de cajero'],
  'auto_categorizar': ['SI', 'Aplicar las reglas al momento de ingerir'],
  'transferencias_terceros': [
    'IGNORAR',
    'Que hacer con las transferencias a otra persona: IGNORAR, NEUTRO o GASTO'
  ],
  'terceros_siempre_registrar': [
    '',
    'Beneficiarios que si se registran aunque la politica sea IGNORAR'
  ],
  'registrar_debito': [
    'NO',
    'SI = registra tambien los consumos con tarjeta de debito'
  ],
  'cuenta_envios': [
    'EFECTIVO',
    'Cuenta a la que se cargan los Yape, Plin y envios a personas'
  ],
  'debito_siempre_registrar': [
    'PLIN-',
    'Comercios que si se registran aunque el debito este apagado'
  ],
  'suscripciones_si': [
    '',
    'Comercios que SIEMPRE son suscripcion, aunque no cumplan el patron'
  ],
  'suscripciones_no': [
    '',
    'Comercios que NUNCA son suscripcion, aunque el patron los detecte'
  ],
  'dias_ventana_dedup': [
    '2',
    'Ventana en dias para detectar duplicados por huella'
  ],
};
