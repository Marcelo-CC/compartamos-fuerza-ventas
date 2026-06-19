class VentaModel {
  final String id;
  final String nombreCompleto;
  final String dni;
  final String genero;
  final String zona;
  final String tipoNegocio;
  final double score;
  final String segmento;
  final double montoMaximo;
  final String estadoEvaluacion;
  final double ingresoMensual;
  final double gastoMensual;
  final double deudactual; 

  VentaModel({
    required this.id,
    required this.nombreCompleto,
    required this.dni,
    required this.genero,
    required this.zona,
    required this.tipoNegocio,
    required this.score,
    required this.segmento,
    required this.montoMaximo,
    required this.estadoEvaluacion,
    required this.ingresoMensual,
    required this.gastoMensual,
    required this.deudactual, 
  });

  // Mapeo: Transforma el JSON de Supabase en un objeto de Dart
  factory VentaModel.fromJson(Map<String, dynamic> json) {
    return VentaModel(
      id: json['id'] ?? '',
      nombreCompleto: json['nombre_completo'] ?? '', 
      dni: json['dni'] ?? '',
      genero: json['genero'] ?? '',
      zona: json['zona'] ?? '',
      tipoNegocio: json['tipo_negocio'] ?? '',      
      score: (json['score'] as num?)?.toDouble() ?? 0.0, 
      segmento: json['segmento'] ?? '',
      montoMaximo: (json['monto_maximo'] as num?)?.toDouble() ?? 0.0, 
      estadoEvaluacion: json['estado_evaluacion'] ?? '',
      ingresoMensual: (json['ingreso_mensual'] as num?)?.toDouble() ?? 0.0, 
      gastoMensual: (json['gasto_mensual'] as num?)?.toDouble() ?? 0.0, 
      deudactual: (json['deuda_actual'] as num?)?.toDouble() ?? 0.0, 
    );
  }

  // Opcional: Útil si deseas enviar modificaciones de vuelta a Supabase en el futuro
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'dni': dni,
      'genero': genero,
      'zona': zona,
      'tipo_negocio': tipoNegocio,
      'score': score,
      'segmento': segmento,
      'monto_maximo': montoMaximo,
      'estado_evaluacion': estadoEvaluacion,
      'ingreso_mensual': ingresoMensual,
      'gasto_mensual': gastoMensual,
      'deuda_actual': deudactual,
    };
  }
}