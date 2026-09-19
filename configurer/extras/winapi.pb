; обёртки над WINAPI.
EnableExplicit
Procedure.s GetLocaleInfo(Locale.l,LCTYPE.l)
  ; Возвращает строку с информацией о локали по ID.
  ; параметры:
    ; Locale - Идентификатор локали для получения информации,
  ; LCTYPE - Сведения о локали.
  ; чтобы посмотреть константы которые можно использовать в LCTYPE, в пурике наберём: "#LOCALE_".
  ; чтобы ознакомиться с описанием констант, на MSDN смотрим описание функции GetLocaleInfoEx.
  Protected info.s{#MAX_PATH} 
  GetLocaleInfo_(Locale,LCTYPE,@info,SizeOf(info))
  ProcedureReturn info
  EndProcedure
  