/// Constantes de la app que **no** son texto traducible.
///
/// Van acá y no en un widget para que no se dupliquen: la URL de la tienda la
/// usan el aviso de calificación y el botón de compartir del Desafío Diario, y
/// una URL repetida en dos archivos es una que tarde o temprano queda
/// desincronizada.
library;

/// Ficha de la app en Google Play.
const String urlPlayStore =
    'https://play.google.com/store/apps/details?id=dev.matute.slidingpuzzle';
