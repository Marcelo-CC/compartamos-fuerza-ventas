-- CONFIGURACIÓN DEL CORE BASE DE DATOS - COMPARTAMOS BANCO

-- 1. Tabla de Clientes del Core
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    dni VARCHAR(8) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo_negocio VARCHAR(50),
    zona VARCHAR(10),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabla de Solicitudes de Créditos (Fuerza de Ventas)
CREATE TABLE solicitudes_credito (
    id SERIAL PRIMARY KEY,
    cliente_dni VARCHAR(8) REFERENCES clientes(dni),
    monto_solicitado DECIMAL(10,2) NOT NULL,
    estado VARCHAR(20) DEFAULT 'Pendiente',
    fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);