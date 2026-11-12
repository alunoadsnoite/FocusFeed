import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum AppLanguage {
  portuguese('pt-BR', 'Português (Brasil)', Locale('pt', 'BR')),
  english('en-US', 'English', Locale('en', 'US')),
  spanish('es-ES', 'Español', Locale('es', 'ES'));

  const AppLanguage(this.tag, this.label, this.locale);

  final String tag;
  final String label;
  final Locale locale;

  static AppLanguage parse(String? tag) => values.firstWhere(
    (language) => language.tag == tag,
    orElse: () => portuguese,
  );
}

class FocusStrings {
  const FocusStrings(this.locale);

  static const delegate = _FocusStringsDelegate();
  static final _placeholder = RegExp(r'\{(\d+)\}');
  final Locale locale;

  String text(String source, [List<Object> args = const []]) {
    final pair = _translations[source];
    final template = switch (locale.languageCode) {
      'en' => pair?.$1 ?? source,
      'es' => pair?.$2 ?? source,
      _ => source,
    };
    return template.replaceAllMapped(_placeholder, (match) {
      final index = int.parse(match[1]!);
      return index < args.length ? args[index].toString() : match[0]!;
    });
  }
}

extension FocusLocalization on BuildContext {
  FocusStrings get strings =>
      Localizations.of<FocusStrings>(this, FocusStrings) ??
      const FocusStrings(Locale('pt', 'BR'));
}

class _FocusStringsDelegate extends LocalizationsDelegate<FocusStrings> {
  const _FocusStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppLanguage.values.any(
    (language) => language.locale.languageCode == locale.languageCode,
  );

  @override
  Future<FocusStrings> load(Locale locale) =>
      SynchronousFuture(FocusStrings(locale));

  @override
  bool shouldReload(_FocusStringsDelegate old) => false;
}

// Brazilian Portuguese is the source text. Native notices already saved by
// earlier versions use these same strings, so they can be localized on display.
const _translations = <String, (String, String)>{
  "Histórico": ("History", "Historial"),
  "Ajustes": ("Settings", "Ajustes"),
  "Foco": ("Focus", "Enfoque"),
  "Parar a sessão?": ("Stop the session?", "¿Detener la sesión?"),
  "O tempo restante será descartado. Uma recompensa já usada não é devolvida.":
      (
        "The remaining time will be discarded. Used reward time will not be refunded.",
        "Se perderá el tiempo restante. El tiempo de recompensa usado no se devolverá.",
      ),
  "Continuar": ("Continue", "Continuar"),
  "Parar": ("Stop", "Detener"),
  "Tentar carregar novamente": ("Try loading again", "Volver a cargar"),
  "Recompensa ativa — redes liberadas": (
    "Reward active — apps unblocked",
    "Recompensa activa — apps desbloqueadas",
  ),
  "Foco pausado — bloqueio desativado": (
    "Focus paused — blocking off",
    "Enfoque en pausa — bloqueo desactivado",
  ),
  "Bloqueio ativo": ("Blocking active", "Bloqueo activo"),
  "Bloqueio indisponível — verifique permissões e serviço": (
    "Blocking unavailable — check permissions and the service",
    "Bloqueo no disponible — comprueba los permisos y el servicio",
  ),
  "Pronto para focar": ("Ready to focus", "Todo listo para enfocarte"),
  "Uma sessão de cada vez.": ("One session at a time.", "Una sesión a la vez."),
  "Foco concluído hoje: {0}": (
    "Focus completed today: {0}",
    "Enfoque completado hoy: {0}",
  ),
  "Recompensa ao concluir: {0}": (
    "Reward on completion: {0}",
    "Recompensa al terminar: {0}",
  ),
  "Verificar novamente": ("Check again", "Volver a comprobar"),
  "Duração do foco": ("Focus duration", "Duración del enfoque"),
  "{0} minuto": ("{0} minute", "{0} minuto"),
  "{0} minutos": ("{0} minutes", "{0} minutos"),
  "Tempo restante de foco": (
    "Focus time remaining",
    "Tiempo de enfoque restante",
  ),
  "Progresso do foco": ("Focus progress", "Progreso del enfoque"),
  "Retomar Foco": ("Resume focus", "Reanudar enfoque"),
  "Iniciar Foco": ("Start focus", "Iniciar enfoque"),
  "Pausar": ("Pause", "Pausar"),
  "Saldo: {0}": ("Balance: {0}", "Saldo: {0}"),
  "Ganhe 20% do tempo de cada foco concluído.": (
    "Earn 20% of the time from each completed focus session.",
    "Gana el 20 % del tiempo de cada sesión de enfoque completada.",
  ),
  "Liberar redes pausa um foco ativo. Sem foco ativo, os apps escolhidos ficam bloqueados até Parar.":
      (
        "Unblocking apps pauses an active focus session. Otherwise, selected apps remain blocked until you tap Stop.",
        "Desbloquear apps pausa la sesión de enfoque activa. Sin una sesión activa, las apps seleccionadas siguen bloqueadas hasta que pulses Detener.",
      ),
  "Recompensa: {0}": ("Reward: {0}", "Recompensa: {0}"),
  "Sem saldo. Conclua um foco para liberar as redes.": (
    "No reward time left. Complete a focus session to unblock apps.",
    "Sin saldo. Completa una sesión de enfoque para desbloquear las apps.",
  ),
  "Liberar Redes por {0}": (
    "Unblock apps for {0}",
    "Desbloquear apps durante {0}",
  ),
  "Notificações ativadas": ("Notifications on", "Notificaciones activadas"),
  "Notificações desativadas": (
    "Notifications off",
    "Notificaciones desactivadas",
  ),
  "Receba avisos ao terminar o foco e a pausa.": (
    "Get alerts when focus or break time ends.",
    "Recibe avisos cuando termine el enfoque o la pausa.",
  ),
  "Configurar": ("Configure", "Configurar"),
  "Apps selecionados para bloqueio": (
    "Apps selected for blocking",
    "Apps seleccionadas para bloquear",
  ),
  "{0} itens selecionados pelo Screen Time": (
    "Items selected in Screen Time: {0}",
    "Elementos seleccionados en Tiempo en pantalla: {0}",
  ),
  "Selecionar apps no iOS": ("Select apps on iOS", "Seleccionar apps en iOS"),
  "Buscar apps instalados": ("Search installed apps", "Buscar apps instaladas"),
  "Nenhum app encontrado. Atualize após instalar um app.": (
    "No apps found. Refresh after installing an app.",
    "No se encontraron apps. Actualiza la lista después de instalar una.",
  ),
  "Atualizar apps instalados": (
    "Refresh installed apps",
    "Actualizar apps instaladas",
  ),
  "Seu progresso": ("Your progress", "Tu progreso"),
  "Hoje": ("Today", "Hoy"),
  "Últimos {0} dias": ("Last {0} days", "Últimos {0} días"),
  "Sequência": ("Streak", "Racha"),
  "{0} dia": ("{0} day", "{0} día"),
  "{0} dias": ("{0} days", "{0} días"),
  "Total": ("Total", "Total"),
  "Ainda não há focos concluídos. Termine uma sessão para começar seu histórico.":
      (
        "No completed focus sessions yet. Finish a session to start your history.",
        "Aún no hay sesiones de enfoque completadas. Termina una para empezar tu historial.",
      ),
  "Detalhes": ("Details", "Detalles"),
  "Sem foco": ("No focus time", "Sin tiempo de enfoque"),
  "Idioma": ("Language", "Idioma"),
  "Aparência": ("Appearance", "Apariencia"),
  "Escolha o tema do aplicativo. O modo automático acompanha o sistema.": (
    "Choose the app theme. Automatic follows your device.",
    "Elige el tema de la app. El modo automático sigue al dispositivo.",
  ),
  "Claro": ("Light", "Claro"),
  "Escuro": ("Dark", "Oscuro"),
  "Auto": ("Auto", "Auto"),
  "Desenvolvedor": ("Developer", "Desarrollador"),
  "E-mail copiado.": ("Email address copied.", "Correo copiado."),
  "Copiar e-mail": ("Copy email address", "Copiar correo"),
  "Sobre": ("About", "Acerca de"),
  "FocusFeed é um Pomodoro offline com bloqueio de apps e recompensa proporcional. Não há conta, anúncios, analytics nem conexão de rede em tempo de execução. Todo o progresso fica no aparelho.":
      (
        "FocusFeed is an offline Pomodoro timer with app blocking and proportional rewards. It runs without an account, ads, analytics or a network connection. All progress stays on your device.",
        "FocusFeed es un temporizador Pomodoro sin conexión con bloqueo de apps y recompensas proporcionales. Funciona sin cuenta, anuncios, analítica ni conexión de red. Todo el progreso se guarda en el dispositivo.",
      ),
  "Acesso ao uso dos apps": ("App usage access", "Acceso al uso de apps"),
  "Sobrepor outros apps": (
    "Display over other apps",
    "Mostrar sobre otras apps",
  ),
  "Autorizar Screen Time": (
    "Authorize Screen Time",
    "Autorizar Tiempo en pantalla",
  ),
  "Permite consultar quais apps foram usados. Selecione FocusFeed e autorize o acesso.":
      (
        "Lets FocusFeed check which apps were used. Select FocusFeed and grant access.",
        "Permite a FocusFeed consultar qué apps se usaron. Selecciona FocusFeed y concede el acceso.",
      ),
  "Permite identificar mudanças de app. Selecione FocusFeed e ative o serviço. Não lê o conteúdo das telas.":
      (
        "Lets FocusFeed detect app changes. Select FocusFeed and enable the service. Screen content stays private.",
        "Permite detectar cambios de app. Selecciona FocusFeed y activa el servicio. El contenido de las pantallas sigue siendo privado.",
      ),
  "Permite exibir a futura tela de bloqueio sobre outros apps. Autorize FocusFeed nas configurações.":
      (
        "Lets FocusFeed show its blocking screen over other apps. Grant access in Settings.",
        "Permite a FocusFeed mostrar la pantalla de bloqueo sobre otras apps. Autoriza el acceso en Ajustes.",
      ),
  "Autoriza o uso do Screen Time para a futura seleção, monitoração e restrição de apps.":
      (
        "Allows Screen Time to select, monitor and restrict apps.",
        "Permite usar Tiempo en pantalla para seleccionar, supervisar y restringir apps.",
      ),
  "Não foi possível verificar as permissões. Tente novamente.": (
    "Could not check permissions. Try again.",
    "No se pudieron comprobar los permisos. Inténtalo de nuevo.",
  ),
  "Não foi possível solicitar a permissão.": (
    "Could not request permission.",
    "No se pudo solicitar el permiso.",
  ),
  "Não foi possível abrir a solicitação.": (
    "Could not open the permission request.",
    "No se pudo abrir la solicitud de permiso.",
  ),
  "Permissões concedidas": ("Permissions granted", "Permisos concedidos"),
  "Permissões para bloqueio": (
    "Permissions for app blocking",
    "Permisos para bloquear apps",
  ),
  "Autorize o monitoramento e bloqueio dos apps escolhidos. Notificações são opcionais.":
      (
        "Allow monitoring and blocking of selected apps. Notifications are optional.",
        "Autoriza la supervisión y el bloqueo de las apps seleccionadas. Las notificaciones son opcionales.",
      ),
  "Disponível em Android e iOS 16 ou superior.": (
    "Available on Android and iOS 16 or later.",
    "Disponible en Android y en iOS 16 o posterior.",
  ),
  "ativado": ("on", "activado"),
  "pendente": ("pending", "pendiente"),
  "Abrir Configurações": ("Open settings", "Abrir ajustes"),
  "Verificar permissões": ("Check permissions", "Comprobar permisos"),
  "Falha na operação nativa.": (
    "The system operation failed.",
    "Falló la operación del sistema.",
  ),
  "Não foi possível carregar a sessão. Tente novamente.": (
    "Could not load the session. Try again.",
    "No se pudo cargar la sesión. Inténtalo de nuevo.",
  ),
  "Saldo insuficiente. Conclua uma sessão de foco para ganhar recompensa.": (
    "Not enough reward time. Complete a focus session to earn more.",
    "Saldo insuficiente. Completa una sesión de enfoque para ganar más tiempo.",
  ),
  "Não foi possível abrir as configurações.": (
    "Could not open settings.",
    "No se pudieron abrir los ajustes.",
  ),
  "Solicitação já aberta.": (
    "A request is already open.",
    "Ya hay una solicitud abierta.",
  ),
  "Ative acesso ao uso e sobreposição no painel de permissões.": (
    "Enable usage access and display over other apps in the permissions panel.",
    "Activa el acceso al uso y la superposición en el panel de permisos.",
  ),
  "Ative acesso ao uso e sobreposição antes de liberar as redes.": (
    "Enable usage access and display over other apps before unblocking apps.",
    "Activa el acceso al uso y la superposición antes de desbloquear las apps.",
  ),
  "Pare a sessão antes de alterar a duração.": (
    "Stop the session before changing its duration.",
    "Detén la sesión antes de cambiar su duración.",
  ),
  "Pare o bloqueio antes de alterar a seleção.": (
    "Stop blocking before changing the selection.",
    "Detén el bloqueo antes de cambiar la selección.",
  ),
  "Não foi possível iniciar o serviço; a alteração foi desfeita.": (
    "Could not start the service. The change was reverted.",
    "No se pudo iniciar el servicio. Se deshizo el cambio.",
  ),
  "Falha ao salvar a sessão.": (
    "Could not save the session.",
    "No se pudo guardar la sesión.",
  ),
  "Solicitação de notificação interrompida.": (
    "The notification request was interrupted.",
    "Se interrumpió la solicitud de notificaciones.",
  ),
  "Escolha uma duração entre 1 segundo e 60 minutos.": (
    "Choose a duration between 1 second and 60 minutes.",
    "Elige una duración entre 1 segundo y 60 minutos.",
  ),
  "Já existe uma sessão ativa.": (
    "A session is already active.",
    "Ya hay una sesión activa.",
  ),
  "Celular reiniciado. O foco foi pausado; nenhum crédito foi gerado durante a interrupção.":
      (
        "Phone restarted. Focus was paused and no reward time was earned during the interruption.",
        "El teléfono se reinició. Se pausó el enfoque y no se ganó tiempo de recompensa durante la interrupción.",
      ),
  "Celular reiniciado. Retome o foco pausado no FocusFeed; nenhum crédito foi gerado enquanto estava desligado.":
      (
        "Phone restarted. Resume focus in FocusFeed. No reward time was earned while the phone was off.",
        "El teléfono se reinició. Reanuda el enfoque en FocusFeed. No se ganó tiempo de recompensa mientras estaba apagado.",
      ),
  "Foco concluído. Recompensa adicionada ao saldo.": (
    "Focus complete. Reward time was added to your balance.",
    "Enfoque completado. La recompensa se añadió al saldo.",
  ),
  "Saldo de recompensa insuficiente.": (
    "Not enough reward time.",
    "Saldo de recompensa insuficiente.",
  ),
  "Já existe uma recompensa ativa.": (
    "A reward is already active.",
    "Ya hay una recompensa activa.",
  ),
  "Não há foco em andamento.": (
    "No focus session is in progress.",
    "No hay ninguna sesión de enfoque en curso.",
  ),
  "Permissão revogada. Monitor interrompido e foco pausado.": (
    "Permission revoked. Monitoring stopped and focus was paused.",
    "Se revocó el permiso. Se detuvo la supervisión y se pausó el enfoque.",
  ),
  "Monitor indisponível. Retome o foco no app.": (
    "Monitoring unavailable. Resume focus in the app.",
    "Supervisión no disponible. Reanuda el enfoque en la app.",
  ),
  "Falha ao salvar a sessão. Retome pelo app.": (
    "Could not save the session. Resume in the app.",
    "No se pudo guardar la sesión. Reanúdala en la app.",
  ),
  "Monitor interrompido. Foco pausado para evitar contar tempo sem proteção.": (
    "Monitoring stopped. Focus was paused so unprotected time would not be counted.",
    "Se detuvo la supervisión. Se pausó el enfoque para evitar contar tiempo sin protección.",
  ),
  "Não foi possível salvar o progresso.": (
    "Could not save progress.",
    "No se pudo guardar el progreso.",
  ),
  "Versão de progresso incompatível.": (
    "Incompatible progress version.",
    "Versión de progreso incompatible.",
  ),
  "Permissão desconhecida": ("Unknown permission", "Permiso desconocido"),
  "Permissão desconhecida.": ("Unknown permission.", "Permiso desconocido."),
  "Screen Time individual exige iOS 16 ou superior.": (
    "Individual Screen Time requires iOS 16 or later.",
    "Tiempo en pantalla individual requiere iOS 16 o posterior.",
  ),
  "Duração inválida.": ("Invalid duration.", "Duración no válida."),
  "Saldo insuficiente ou recompensa já ativa.": (
    "Not enough reward time, or a reward is already active.",
    "Saldo insuficiente o ya hay una recompensa activa.",
  ),
  "Operação desconhecida.": ("Unknown operation.", "Operación desconocida."),
  "O Screen Time não aceitou o agendamento. Nenhum saldo foi gasto. Tente novamente.":
      (
        "Screen Time did not accept the schedule. No reward time was spent. Try again.",
        "Tiempo en pantalla no aceptó la programación. No se gastó saldo. Inténtalo de nuevo.",
      ),
  "Seleção já aberta.": (
    "The app picker is already open.",
    "El selector de apps ya está abierto.",
  ),
  "Pare a sessão e autorize Screen Time antes de selecionar apps.": (
    "Stop the session and authorize Screen Time before selecting apps.",
    "Detén la sesión y autoriza Tiempo en pantalla antes de seleccionar apps.",
  ),
  "Tela indisponível.": ("Screen unavailable.", "Pantalla no disponible."),
  "Monitor Screen Time interrompido. Abra o FocusFeed para retomar.": (
    "Screen Time monitoring stopped. Open FocusFeed to resume.",
    "Se detuvo la supervisión de Tiempo en pantalla. Abre FocusFeed para reanudar.",
  ),
  "Configure o App Group e a assinatura no Xcode para salvar a sessão compartilhada.":
      (
        "Configure the App Group and signing in Xcode to save the shared session.",
        "Configura el grupo de apps y la firma en Xcode para guardar la sesión compartida.",
      ),
  "Falha no armazenamento local.": (
    "Local storage failed.",
    "Falló el almacenamiento local.",
  ),
  "Falha ao acessar o progresso.": (
    "Could not access progress.",
    "No se pudo acceder al progreso.",
  ),
  "Progresso salvo inválido; nenhum dado foi sobrescrito.": (
    "Saved progress is invalid. Your data was left intact.",
    "El progreso guardado no es válido. Tus datos siguen intactos.",
  ),
  "Progresso anterior inválido.": (
    "Previous progress is invalid.",
    "El progreso anterior no es válido.",
  ),
  "Celular reiniciado ou relógio alterado. O foco foi pausado sem gerar crédito durante a interrupção.":
      (
        "The phone restarted or its clock changed. Focus paused without earning reward time during the interruption.",
        "El teléfono se reinició o cambió su reloj. Se pausó el enfoque sin ganar tiempo de recompensa durante la interrupción.",
      ),
  "Autorização Screen Time revogada. Retome o foco após autorizar.": (
    "Screen Time access was revoked. Grant access to resume focus.",
    "Se revocó el acceso a Tiempo en pantalla. Autoriza el acceso para reanudar el enfoque.",
  ),
  "Monitor interrompido. Foco pausado para evitar crédito sem proteção.": (
    "Monitoring stopped. Focus paused so unprotected time would not be counted.",
    "Se detuvo la supervisión. Se pausó el enfoque para evitar contar tiempo sin protección.",
  ),
};
