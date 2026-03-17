// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Examen Sake N2';

  @override
  String get homeTitle => 'Examen Sake N2: Estudio y Quiz';

  @override
  String get homeSubtitle => '¡Domina el conocimiento avanzado del Sake!';

  @override
  String get part1Title => 'Ingredientes y Agua';

  @override
  String get part2Title => 'Proceso de Producción';

  @override
  String get part3Title => 'Etiquetas y Estilos';

  @override
  String get part4Title => 'Servicio y Maridaje';

  @override
  String get reviewWeakness => 'Repasar Debilidades';

  @override
  String get correct => '¡Correcto!';

  @override
  String get incorrect => 'Incorrecto...';

  @override
  String get questionLabel => 'Pregunta';

  @override
  String get resultTitle => 'Resultado';

  @override
  String get backToHome => 'Volver al Inicio';

  @override
  String get loading => 'Cargando...';

  @override
  String get noData => 'No hay datos disponibles';

  @override
  String get perfectMessage => '¡PERFECTO! 🎉';

  @override
  String get passMessage => '¡Gran trabajo! ¡Aprobaste!';

  @override
  String get failMessage => '¡Casi! Repasemos.';

  @override
  String get imageQuestion => 'Pregunta con Imagen';

  @override
  String get reviewMistakes => 'Revisar Errores';

  @override
  String get retry => 'Reintentar';

  @override
  String get scoreLabel => 'Puntuación';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get restorePurchases => 'Restaurar Compras';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get contactUs => 'Contáctenos';

  @override
  String get appVersion => 'Versión';

  @override
  String get premiumUnlock => 'Desbloquear Premium';

  @override
  String get premiumDesc => 'Desbloquear todo y quitar anuncios';

  @override
  String get purchaseSuccess => '¡Compra exitosa!';

  @override
  String get restoreSuccess => '¡Compras restauradas!';

  @override
  String get restoreFail => 'Nada para restaurar.';

  @override
  String get locked => 'Bloqueado';

  @override
  String get buy => 'Comprar';

  @override
  String get sisterAppTitle =>
      'Amplía tus conocimientos con nuestras otras aplicaciones';

  @override
  String get sisterAppSubtitle => '¡Desafía otro nivel!';

  @override
  String get sisterAppPopupTitle => 'Otras aplicaciones';

  @override
  String get sisterAppPopupBody =>
      'Abriendo la App Store para visitar la página de la aplicación.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get open => 'Abrir';

  @override
  String get shuffle => 'Aleatorio';

  @override
  String get sequential => 'Secuencial';

  @override
  String get premiumUpgradeTitle => 'Mejora Premium';

  @override
  String get premiumFeatureSequential =>
      'Modo \'Secuencial\': Resuelva todas las preguntas en orden desde la primera.';

  @override
  String get premiumFeatureAds =>
      'Sin anuncios: Oculte todos los banners y videos de la aplicación.';

  @override
  String get premiumFeatureCategory =>
      'Repaso por categorías: Repase sus puntos débiles por capítulo de manera eficiente.';

  @override
  String get upgradeNow => 'Mejorar ahora';

  @override
  String get whichPartToReview => '¿Qué parte quieres repasar?';

  @override
  String get allCategories => 'Todas las categorías';

  @override
  String questionCount(Object count) {
    return '$count preguntas';
  }
}
